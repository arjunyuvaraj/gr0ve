import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/features/club/widgets/club_browse_tab.dart';
import 'package:gr0ve/features/club/widgets/club_create_tab.dart';
import 'package:gr0ve/features/club/widgets/club_my_clubs_tab.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    FirebaseAnalytics.instance.logEvent(name: 'screen_club_main');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = Theme.of(context).colorScheme;

    if (user == null) {
      return const Center(child: Text('Please sign in to view clubs'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          /// Header
          CustomHeader(title: "Groups".capitalized),
          const SizedBox(height: 16),

          /// Tabs (segmented control style) with notification indicator
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors.onSurface.withAlpha(14),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurface.withAlpha(140),
              tabs: [
                const Tab(text: "Browse"),
                // My Clubs tab with notification indicator
                Tab(
                  child: StreamBuilder<Map<String, dynamic>>(
                    stream: NotificationService().unreadCountStream,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      bool hasUnread = false;

                      if (data != null) {
                        final announcementsMap =
                            data['announcementsByClub'] != null
                            ? Map.from(data['announcementsByClub'] as Map)
                            : null;
                        final qaMap = data['qaByClub'] != null
                            ? Map.from(data['qaByClub'] as Map)
                            : null;

                        final Map<String, int> announcements =
                            announcementsMap?.map(
                              (key, value) =>
                                  MapEntry(key.toString(), value as int),
                            ) ??
                            {};
                        final Map<String, int> unreadQA =
                            qaMap?.map(
                              (key, value) =>
                                  MapEntry(key.toString(), value as int),
                            ) ??
                            {};

                        hasUnread =
                            announcements.values.any((c) => c > 0) ||
                            unreadQA.values.any((c) => c > 0);
                      } else {
                        // Initial load
                        hasUnread =
                            NotificationService()
                                .unreadAnnouncementsByClub
                                .values
                                .any((c) => c > 0) ||
                            NotificationService().unreadQAByClub.values.any(
                              (c) => c > 0,
                            );
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Text("My Clubs"),
                          if (hasUnread)
                            Positioned(
                              right: -12,
                              top: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const Tab(text: "Create"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ClubBrowseTab(),
                ClubMyClubsTab(),
                ClubCreateTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
