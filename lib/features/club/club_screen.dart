import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/components/club_browse_tab.dart';
import 'package:gr0ve/components/club_create_tab.dart';
import 'package:gr0ve/components/club_my_clubs_tab.dart';
import 'package:gr0ve/components/custom_header.dart';
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

  // Track unread announcements
  Map<String, int> _unreadAnnouncementsByClub = {};
  bool _hasUnreadAnnouncements = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    NotificationService().unreadCountStream.listen((data) {
      if (mounted) {
        setState(() {
          // Convert from Map<dynamic, dynamic> to Map<String, int>
          final announcementsMap =
              data['announcementsByClub'] as Map<dynamic, dynamic>?;
          _unreadAnnouncementsByClub =
              announcementsMap?.map(
                (key, value) => MapEntry(key.toString(), value as int),
              ) ??
              {};
          _hasUnreadAnnouncements = _unreadAnnouncementsByClub.values.any(
            (count) => count > 0,
          );
        });
      }
    });

    // Get initial counts
    setState(() {
      _unreadAnnouncementsByClub =
          NotificationService().unreadAnnouncementsByClub;
      _hasUnreadAnnouncements = _unreadAnnouncementsByClub.values.any(
        (count) => count > 0,
      );
    });
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          /// Header
          CustomHeader(
            title: "Groups".capitalized,
            subtitle: "Yes, you are unfortunately social.",
          ),
          const SizedBox(height: 12),

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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text("My Clubs"),
                      if (_hasUnreadAnnouncements)
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
