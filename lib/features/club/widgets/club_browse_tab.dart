import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/cards/custom_group_card.dart';
import 'package:gr0ve/features/club/widgets/join_with_code_card.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/models/group.dart';
import 'package:gr0ve/features/club/services/group_service.dart';
import 'package:gr0ve/features/club/widgets/join_code_dialog.dart';
import 'package:gr0ve/features/club/screens/club_detail_screen.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';

class ClubBrowseTab extends StatefulWidget {
  const ClubBrowseTab({super.key});

  @override
  State<ClubBrowseTab> createState() => _ClubBrowseTabState();
}

class _ClubBrowseTabState extends State<ClubBrowseTab> {
  final GroupService _groupService = GroupService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  void _openJoinDialog() {
    showDialog(context: context, builder: (_) => const JoinCodeDialog());
  }

  void _navigateToClub(String clubId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubDetailScreen(groupId: clubId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return StreamBuilder<List<Group>>(
      stream: _groupService.getUserGroups(),
      builder: (context, joinedSnapshot) {
        final joinedGroups = joinedSnapshot.data ?? [];
        final joinedGroupIds = joinedGroups.map((g) => g.id).toSet();

        return StreamBuilder<Map<String, int>>(
          stream: _notificationService.unreadCountStream.map(
            (data) => Map<String, int>.from(data['announcementsByClub'] ?? {}),
          ),
          initialData: _notificationService.unreadAnnouncementsByClub,
          builder: (context, notifSnapshot) {
            final unreadCounts = notifSnapshot.data ?? {};

            return StreamBuilder<List<Group>>(
              stream: _groupService.getActiveGroups(type: GroupType.club),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Something went wrong. Groups remain elusive.",
                      style: context.text.bodyMedium,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clubs = snapshot.data ?? [];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;

                    if (isWide) {
                      return _buildWideLayout(
                        context,
                        clubs,
                        joinedGroupIds,
                        unreadCounts,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 110),
                      itemCount: clubs.isEmpty ? 4 : clubs.length + 2,
                      itemBuilder: (context, index) {
                        // Index 0: Join Code Card
                        if (index == 0) {
                          return JoinWithCodeCard(
                            controller: _joinCodeController,
                            onJoinPressed: _openJoinDialog,
                          );
                        }

                        // Index 1: Spacing
                        if (index == 1) {
                          return const SizedBox(height: 20);
                        }

                        // Empty state handling
                        if (clubs.isEmpty) {
                          if (index == 2) {
                            return Column(
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.groups_outlined,
                                  size: 64,
                                  color: colors.onSurface.withAlpha(100),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No groups yet",
                                  textAlign: TextAlign.center,
                                  style: context.text.titleMedium,
                                ),
                              ],
                            );
                          }
                          if (index == 3) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Either nobody made one or nobody invited you.",
                                textAlign: TextAlign.center,
                                style: context.text.bodySmall?.copyWith(
                                  color: colors.onSurface.withAlpha(140),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        // Header for available groups
                        if (index == 2) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Available groups",
                              style: context.text.titleSmall?.copyWith(
                                color: colors.onSurface.withAlpha(160),
                              ),
                            ),
                          );
                        }

                        // Actual club cards
                        final clubIndex = index - 3;
                        if (clubIndex < 0 || clubIndex >= clubs.length) {
                          return const SizedBox.shrink();
                        }

                        final club = clubs[clubIndex];
                        final isJoined = joinedGroupIds.contains(club.id);
                        final unreadCount = unreadCounts[club.id] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomGroupCard(
                            name: club.name,
                            description: club.description,
                            hasNotification: unreadCount > 0,
                            onTap: isJoined
                                ? () => _navigateToClub(club.id)
                                : _openJoinDialog,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    List<Group> clubs,
    Set<String> joinedGroupIds,
    Map<String, int> unreadCounts,
  ) {
    final colors = context.colors;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: JoinWithCodeCard(
              controller: _joinCodeController,
              onJoinPressed: _openJoinDialog,
            ),
          ),
        ),
        if (clubs.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: colors.onSurface.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text("No groups yet", style: context.text.titleMedium),
                ],
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Available groups",
                style: context.text.titleSmall?.copyWith(
                  color: colors.onSurface.withAlpha(160),
                ),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 140, // Height of CustomGroupCard
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final club = clubs[index];
              final isJoined = joinedGroupIds.contains(club.id);
              final unreadCount = unreadCounts[club.id] ?? 0;

              return CustomGroupCard(
                name: club.name,
                description: club.description,
                hasNotification: unreadCount > 0,
                onTap: isJoined
                    ? () => _navigateToClub(club.id)
                    : _openJoinDialog,
              );
            }, childCount: clubs.length),
          ),
        ],
      ],
    );
  }
}
