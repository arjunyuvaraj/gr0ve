import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'package:gr0ve/features/club/services/group_service.dart';
import 'package:gr0ve/models/group.dart';

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
  String _eventScope = 'personal';
  bool _isAllDay = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _errorMessage;

  Group? _userClub;
  bool _isClubAdmin = false;
  bool _isLoadingClubInfo = true;

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
    FirebaseAnalytics.instance.logEvent(name: 'calendar_add_event');
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
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
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
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        FirebaseAnalytics.instance.logEvent(name: "add_event_personal");
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
              content: Text('Group event added successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        FirebaseAnalytics.instance.logEvent(name: "add_event_club");
      } else if (_eventScope == 'public') {
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
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Public event request submitted for admin approval',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        FirebaseAnalytics.instance.logEvent(name: "add_event_public");
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event_rounded,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Event',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              '${widget.selectedDate.month}/${widget.selectedDate.day}/${widget.selectedDate.year}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if ((widget.isPlatformAdmin || _isClubAdmin) &&
                      !_isLoadingClubInfo) ...[
                    Text(
                      'EVENT VISIBILITY',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScopeOption(
                            'Personal',
                            Icons.person_rounded,
                            'personal',
                            colors,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScopeOption(
                            'Group',
                            Icons.group_rounded,
                            'club',
                            colors,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScopeOption(
                            'Public',
                            Icons.public_rounded,
                            'public',
                            colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_eventScope == 'public' && !widget.isPlatformAdmin)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Public events require admin approval',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_eventScope == 'club') ...[
                      const SizedBox(height: 16),
                      if (_isLoadingAdminGroups)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          ),
                        )
                      else if (_adminGroups.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.error.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                size: 18,
                                color: colors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You are not an admin of any groups',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Group>(
                          value: _selectedGroup,
                          decoration: InputDecoration(
                            labelText: 'Select Group',
                            prefixIcon: Icon(
                              Icons.group_rounded,
                              color: colors.primary,
                            ),
                            filled: true,
                            fillColor: colors.surface.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outline.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outline.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 2,
                              ),
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
                    ],
                    const SizedBox(height: 24),
                  ],

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Event Title',
                      hintText: 'Enter event title',
                      prefixIcon: Icon(
                        Icons.title_rounded,
                        color: colors.primary,
                      ),
                      filled: true,
                      fillColor: colors.surface.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.outline.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.outline.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add details about your event',
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        color: colors.primary,
                      ),
                      filled: true,
                      fillColor: colors.surface.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.outline.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.outline.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  if (_eventScope == 'personal') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(
                          Icons.category_rounded,
                          color: colors.primary,
                        ),
                        labelStyle: TextStyle(color: context.colors.primary),
                        floatingLabelStyle: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: colors.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.outline.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.outline.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['value'] as String,
                          child: Row(
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 18,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 12),
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

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All Day Event',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isAllDay,
                          onChanged: (v) => setState(() {
                            _isAllDay = v;
                            _errorMessage = null;
                          }),
                        ),
                      ],
                    ),
                  ),

                  if (!_isAllDay) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _startTime?.format(context) ?? 'Start Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _endTime?.format(context) ?? 'End Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: colors.surface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _saveEvent,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _eventScope == 'public' && !widget.isPlatformAdmin
                                  ? 'Submit Request'
                                  : 'Save Event',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScopeOption(
    String label,
    IconData icon,
    String value,
    ColorScheme colors,
  ) {
    final isSelected = _eventScope == value;
    return InkWell(
      onTap: () {
        setState(() {
          _eventScope = value;

          if (_eventScope == 'club' &&
              _adminGroups.isEmpty &&
              !_isLoadingAdminGroups) {
            _loadAdminGroups();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withOpacity(0.15)
              : colors.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colors.primary
                  : colors.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
