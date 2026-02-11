import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/features/calendar/calendar_service.dart';
import 'package:gr0ve/features/club/group_service.dart';
import 'package:gr0ve/features/club/group.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final bool isPlatformAdmin;

  const AddEventDialog({
    super.key,
    required this.selectedDate,
    this.isPlatformAdmin = false,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'homework';
  String _eventScope = 'personal'; // personal, club, public
  bool _isAllDay = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _errorMessage;

  Group? _userClub;
  bool _isClubAdmin = false;
  bool _isLoadingClubInfo = true;

  // For group selection dropdown
  List<Group> _adminGroups = [];
  Group? _selectedGroup;
  bool _isLoadingAdminGroups = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'test', 'label': 'Test', 'icon': Icons.assignment},
    {'value': 'quiz', 'label': 'Quiz', 'icon': Icons.quiz},
    {'value': 'homework', 'label': 'Homework', 'icon': Icons.book},
    {'value': 'project', 'label': 'Project', 'icon': Icons.work},
    {'value': 'social', 'label': 'Social', 'icon': Icons.people},
    {'value': 'other', 'label': 'Other', 'icon': Icons.event},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserClubStatus();
  }

  Future<void> _loadUserClubStatus() async {
    final groupService = GroupService();
    final club = await groupService.getUserClub();

    if (club != null) {
      final isAdmin = await groupService.isGroupAdmin(club.id);
      if (mounted) {
        setState(() {
          _userClub = club;
          _isClubAdmin = isAdmin;
          _isLoadingClubInfo = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingClubInfo = false);
    }
  }

  Future<void> _loadAdminGroups() async {
    if (_isLoadingAdminGroups) return;

    setState(() => _isLoadingAdminGroups = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _adminGroups = [];
          _isLoadingAdminGroups = false;
        });
        return;
      }

      // Get all active groups
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      final adminGroups = <Group>[];
      for (final doc in groupsSnapshot.docs) {
        final group = Group.fromFirestore(doc);
        if (group.isAdmin(user.uid)) {
          adminGroups.add(group);
        }
      }

      if (mounted) {
        setState(() {
          _adminGroups = adminGroups;
          _isLoadingAdminGroups = false;
          // Auto-select first group if available and none selected
          if (_selectedGroup == null && adminGroups.isNotEmpty) {
            _selectedGroup = adminGroups.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adminGroups = [];
          _isLoadingAdminGroups = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isStart)
          _startTime = time;
        else
          _endTime = time;
        _errorMessage = null;
      });
    }
  }

  Future<void> _saveEvent() async {
    setState(() => _errorMessage = null);

    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a title');
      return;
    }

    if (!_isAllDay && _startTime == null) {
      setState(() => _errorMessage = 'Please select a start time');
      return;
    }

    final now = DateTime.now();
    final eventDate = widget.selectedDate;

    DateTime? startTime;
    DateTime? endTime;

    if (!_isAllDay && _startTime != null) {
      startTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      if (_endTime != null) {
        endTime = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }
    }

    final event = CalendarEvent(
      id: 'temp_${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      date: eventDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _eventScope == 'personal' ? 'personal' : 'club',
      personalCategory: _selectedCategory,
      isAllDay: _isAllDay,
      startTime: startTime,
      endTime: endTime,
    );

    try {
      if (_eventScope == 'personal') {
        await CalendarService.addPersonalEvent(event);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Personal event added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (_eventScope == 'club') {
        if (_selectedGroup == null) {
          setState(() => _errorMessage = 'Please select a group');
          return;
        }
        await CalendarService.addClubEvent(_selectedGroup!.id, event);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Club event added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (_eventScope == 'public') {
        // Request public event (requires admin approval unless platform admin)
        final groupId = _selectedGroup?.id ?? _userClub?.id ?? 'platform';
        final groupName =
            _selectedGroup?.name ?? _userClub?.name ?? 'Platform Admin';

        await CalendarService.requestPublicEvent(
          groupId: groupId,
          groupName: groupName,
          event: event,
          bypassApproval: widget.isPlatformAdmin,
        );

        if (mounted) {
          Navigator.of(context).pop();
          if (widget.isPlatformAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Public event added to BCA calendar'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Public event request submitted for admin approval',
                ),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Event',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    color: colors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Event Scope Selector (only for admins or club admins)
                if ((widget.isPlatformAdmin || _isClubAdmin) &&
                    !_isLoadingClubInfo) ...[
                  Text(
                    'Event Visibility',
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'personal',
                        label: Text('Personal', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.person, size: 16),
                      ),
                      ButtonSegment(
                        value: 'club',
                        label: Text('Group', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.group, size: 16),
                      ),
                      ButtonSegment(
                        value: 'public',
                        label: Text('Public', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.public, size: 16),
                      ),
                    ],
                    selected: {_eventScope},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _eventScope = newSelection.first;
                        // Load admin groups when group scope is selected
                        if (_eventScope == 'club' &&
                            _adminGroups.isEmpty &&
                            !_isLoadingAdminGroups) {
                          _loadAdminGroups();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Info banner for public events
                  if (_eventScope == 'public' && !widget.isPlatformAdmin)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Public events require admin approval before appearing on BCA calendar',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Group dropdown when group scope is selected
                  if (_eventScope == 'club') ...[
                    if (_isLoadingAdminGroups)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_adminGroups.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.errorContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.errorContainer.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'You are not an admin of any groups',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<Group>(
                        value: _selectedGroup,
                        decoration: InputDecoration(
                          labelText: 'Select Group',
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _adminGroups.map((group) {
                          return DropdownMenuItem<Group>(
                            value: group,
                            child: Text(group.name),
                          );
                        }).toList(),
                        onChanged: (Group? value) {
                          setState(() => _selectedGroup = value);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 20),
                ],

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.errorContainer.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Title',
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null)
                      setState(() => _errorMessage = null);
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Category for personal events
                if (_eventScope == 'personal') ...[
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['value'] as String,
                        child: Row(
                          children: [
                            Icon(cat['icon'] as IconData),
                            const SizedBox(width: 8),
                            Text(cat['label'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                ],

                // All Day toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('All Day'),
                    Switch(
                      value: _isAllDay,
                      onChanged: (v) => setState(() {
                        _isAllDay = v;
                        _errorMessage = null;
                      }),
                    ),
                  ],
                ),

                // Start/End times if not all day
                if (!_isAllDay)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text(
                            _startTime?.format(context) ?? 'Start Time',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selectTime(context, false),
                          child: Text(_endTime?.format(context) ?? 'End Time'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      child: Text(
                        _eventScope == 'public' && !widget.isPlatformAdmin
                            ? 'Submit Request'
                            : 'Save',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
