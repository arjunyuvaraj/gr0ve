import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/club/widgets/club_browse_tab.dart';
import 'package:gr0ve/features/club/widgets/club_create_tab.dart';
import 'package:gr0ve/features/club/widgets/club_my_clubs_tab.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

import 'package:gr0ve/core/widgets/misc/email_verification_gate.dart';

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
    final colors = Theme.of(context).colorScheme;

    return EmailVerificationGate(
      description: "Please verify your email address to access BCA Groups.",
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: CustomHeader(title: "Groups".capitalized),
            ),
            const SizedBox(height: 16),

            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
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
                  labelPadding: EdgeInsets.zero,
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
                              const Text(
                                "My Groups",
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
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
            ),

            const SizedBox(height: 16),

            Expanded(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    ClubBrowseTab(),
                    ClubMyClubsTab(),
                    ClubCreateTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
