import 'package:flutter/material.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/models/group.dart';
import 'package:gr0ve/features/club/services/group_service.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24),
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
                    color: colors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
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
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ADMIN',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        )
                      else if (_isModOrAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'MOD',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                    const SizedBox(height: 6),
                    Text(
                      widget.club.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.5),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        _unreadCount == 1
                            ? '1 new announcement'
                            : '$_unreadCount new announcements',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
