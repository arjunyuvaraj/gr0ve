import 'package:flutter/material.dart';
import 'package:gr0ve/components/admin_pill.dart';
import 'package:gr0ve/models/group.dart';
import 'package:gr0ve/services/group_service.dart';

class MyClubCard extends StatelessWidget {
  final Group club;
  final GroupService groupService;
  final VoidCallback onTap;

  const MyClubCard({
    required this.club,
    required this.groupService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FutureBuilder<bool>(
      future: groupService.isGroupAdmin(club.id),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.onSurface.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          club.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin) AdminPill(),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    club.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
