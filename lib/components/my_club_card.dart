import 'package:flutter/material.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/features/club/group.dart';
import 'package:gr0ve/features/club/group_service.dart';

class MyClubCard extends StatefulWidget {
  final Group club;
  final GroupService groupService;
  final VoidCallback onTap;

  const MyClubCard({
    super.key,
    required this.club,
    required this.groupService,
    required this.onTap,
  });

  @override
  State<MyClubCard> createState() => _MyClubCardState();
}

class _MyClubCardState extends State<MyClubCard> {
  bool _isAdmin = false;
  bool _isModOrAdmin = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _loadUnreadCount();

    // Listen to notification updates
    NotificationService().unreadCountStream.listen((data) {
      if (mounted) {
        // Convert from Map<dynamic, dynamic> to Map<String, int>
        final announcementsMap =
            data['announcementsByClub'] as Map<dynamic, dynamic>?;
        final announcementsByClub =
            announcementsMap?.map(
              (key, value) => MapEntry(key.toString(), value as int),
            ) ??
            {};

        setState(() {
          _unreadCount = announcementsByClub[widget.club.id] ?? 0;
        });
      }
    });
  }

  void _loadUnreadCount() {
    setState(() {
      _unreadCount = NotificationService().getClubUnreadCount(widget.club.id);
    });
  }

  Future<void> _checkRole() async {
    final isAdmin = await widget.groupService.isGroupAdmin(widget.club.id);
    final isModOrAdmin = await widget.groupService.isGroupModOrAdmin(
      widget.club.id,
    );

    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isModOrAdmin = isModOrAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Club icon with notification dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: colors.primary,
                      size: 28,
                    ),
                  ),
                  // Red notification dot
                  if (_unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Club info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.club.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          )
                        else if (_isModOrAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MOD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.club.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        _unreadCount == 1
                            ? '1 new announcement'
                            : '$_unreadCount new announcements',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
