import 'package:flutter/material.dart';
import 'package:gr0ve/services/calendar_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/core/utilities/extensions/context_extensions.dart';

class EventDetailsDialog extends StatefulWidget {
  final CalendarEvent event;

  const EventDetailsDialog({super.key, required this.event});

  @override
  State<EventDetailsDialog> createState() => _EventDetailsDialogState();
}

class _EventDetailsDialogState extends State<EventDetailsDialog> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _canDelete = false;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    bool canDelete = false;

    if (widget.event.category == 'personal') {
      canDelete = true;
    } else if (widget.event.category == 'club') {
      canDelete = await _checkClubEventPermission(user.uid);
    }

    setState(() {
      _canDelete = canDelete;
      _isLoading = false;
    });
  }

  Future<bool> _checkClubEventPermission(String userId) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      for (final groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;

        final eventDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('calendar')
            .doc('events')
            .collection('items')
            .where('id', isEqualTo: widget.event.id)
            .limit(1)
            .get();

        if (eventDoc.docs.isNotEmpty) {
          _groupId = groupId;
          final eventData = eventDoc.docs.first.data();
          final createdBy = eventData['createdBy'] as String?;

          if (createdBy == userId) return true;

          final groupData = groupDoc.data();
          final ownerId = groupData['ownerId'] as String?;
          if (ownerId == userId) return true;

          final memberDoc = await _firestore
              .collection('groups')
              .doc(groupId)
              .collection('members')
              .doc(userId)
              .get();

          if (memberDoc.exists) {
            final role = memberDoc.data()?['role'] as String?;
            if (role == 'owner' || role == 'admin') return true;
          }

          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking club event permission: $e');
      return false;
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (widget.event.category == 'personal') {
        await CalendarService.deletePersonalEvent(widget.event.id);
      } else if (widget.event.category == 'club' && _groupId != null) {
        await _deleteClubEvent(_groupId!);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
      }
    }
  }

  Future<void> _deleteClubEvent(String groupId) async {
    final eventsSnapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('calendar')
        .doc('events')
        .collection('items')
        .where('id', isEqualTo: widget.event.id)
        .limit(1)
        .get();

    if (eventsSnapshot.docs.isNotEmpty) {
      await eventsSnapshot.docs.first.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final isBCA = widget.event.category == 'bca';
    final isClub = widget.event.category == 'club';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.event.title,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 22, color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoRow(
              Icons.calendar_today,
              _formatDate(widget.event.date),
              colors,
              text,
            ),

            if (!widget.event.isAllDay && widget.event.startTime != null)
              _buildInfoRow(
                Icons.access_time,
                '${_formatTime(widget.event.startTime!)}${widget.event.endTime != null ? ' - ${_formatTime(widget.event.endTime!)}' : ''}',
                colors,
                text,
              ),

            _buildInfoRow(
              Icons.category,
              isBCA
                  ? 'BCA Event'
                  : isClub
                  ? 'Club Event'
                  : _getCategoryLabel(widget.event.personalCategory),
              colors,
              text,
            ),

            if (widget.event.description != null) ...[
              const SizedBox(height: 16),
              Text(
                'Description',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.event.description!, style: text.bodyMedium),
            ],

            // Delete button
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                ),
              )
            else if (_canDelete) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _deleteEvent,
                    icon: Icon(Icons.delete, color: colors.error),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String textStr,
    ColorScheme colors,
    TextTheme text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 19, color: colors.secondary),
          const SizedBox(width: 12),
          Expanded(child: Text(textStr, style: text.bodyMedium)),
        ],
      ),
    );
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'test':
        return 'Test';
      case 'quiz':
        return 'Quiz';
      case 'homework':
        return 'Homework';
      case 'project':
        return 'Project';
      case 'social':
        return 'Social';
      default:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
