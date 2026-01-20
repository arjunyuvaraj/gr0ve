import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/components/club_browse_tab.dart';
import 'package:gr0ve/components/club_create_tab.dart';
import 'package:gr0ve/components/club_my_clubs_tab.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/utilities/context_extensions.dart';
import '../services/group_service.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupService _groupService = GroupService();
  bool _isPlatformAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _groupService.isPlatformAdmin();
    if (mounted) {
      setState(() => _isPlatformAdmin = isAdmin);
    }
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

          /// Tabs (segmented control style)
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
              tabs: const [
                Tab(text: "Browse"),
                Tab(text: "My Clubs"),
                Tab(text: "Create"),
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
