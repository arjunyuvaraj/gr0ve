import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/club/widgets/announcment_qa_sheet.dart';
import 'package:gr0ve/features/club/widgets/post_announcement_dialog.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/features/club/services/group_service.dart';
import 'package:gr0ve/models/group.dart';
import 'package:gr0ve/models/announcement.dart';
import 'package:gr0ve/models/group_member.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

class ClubDetailScreen extends StatefulWidget {
  final String groupId;
  final String? initialAnnouncementId;
  final String? initialQuestionId;

  const ClubDetailScreen({
    super.key,
    required this.groupId,
    this.initialAnnouncementId,
    this.initialQuestionId,
  });

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  Group? _group;
  bool _isAdmin = false;
  bool _isModOrAdmin = false;
  bool _isMember = false;
  bool _isLoading = true;

  final Map<String, Map<String, dynamic>> _userProfileCache = {};
  String _memberSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadGroupData();
    FirebaseAnalytics.instance.logEvent(name: 'screen_club_details');
    NotificationService().clearClubAnnouncementCount(widget.groupId);
    // Also clear global qa_replies if the user is entering a club
    // (We don't know for sure which club the reply was for without more logic,
    // but clearing the global one is safe here as a start).
    NotificationService().clearUnreadCount('qa_replies');

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        NotificationService().clearClubAnnouncementCount(widget.groupId);
        NotificationService().clearClubQACount(widget.groupId);
      }
    });

    // Handle deep-linking from notifications
    if (widget.initialAnnouncementId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDeepLinkedQA();
      });
    }
  }

  void _openDeepLinkedQA() async {
    // Wait for group data to load so we have mod/admin status if needed
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnnouncementQASheet(
        groupId: widget.groupId,
        announcementId: widget.initialAnnouncementId!,
        announcementTitle: "Announcement", // Fallback title
        isModOrAdmin: _isModOrAdmin,
        initialQuestionId: widget.initialQuestionId,
      ),
    );
  }

  Future<void> _loadGroupData() async {
    try {
      final group = await _groupService.getGroup(widget.groupId);
      final isAdmin = await _groupService.isGroupAdmin(widget.groupId);
      final isModOrAdmin = await _groupService.isGroupModOrAdmin(
        widget.groupId,
      );
      final isMember = await _groupService.isGroupMember(widget.groupId);

      if (!mounted) return;
      setState(() {
        _group = group;
        _isAdmin = isAdmin;
        _isModOrAdmin = isModOrAdmin;
        _isMember = isMember;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading group: $e')));
    }
  }

  Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId]!;
    }
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final profile = userDoc.data()!;
        _userProfileCache[userId] = profile;
        return profile;
      }
    } catch (e) {
      // ignore
    }
    return {'displayName': 'Unknown', 'email': ''};
  }

  Future<void> _syncMemberProfile(GroupMember member) async {
    final profile = await _getUserProfile(member.userId);
    final latestName = profile['displayName'] ?? member.displayName;
    final latestEmail = profile['email'] ?? member.email;
    if (latestName != member.displayName || latestEmail != member.email) {
      try {
        await _firestore
            .collection('groups')
            .doc(widget.groupId)
            .collection('members')
            .doc(member.userId)
            .update({'displayName': latestName, 'email': latestEmail});
      } catch (e) {
        // Silently fail
      }
    }
  }

  Future<void> _regenerateJoinCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Regenerate Join Code?'),
        content: const Text(
          'This will invalidate the current join code. Members already in the group will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _groupService.regenerateJoinCode(widget.groupId);
      await _loadGroupData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Join code regenerated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _leaveClub() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _groupService.leaveGroup(widget.groupId);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Left group successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showPostAnnouncementDialog() {
    showDialog(
      context: context,
      builder: (_) => PostAnnouncementDialog(groupId: widget.groupId),
    );
  }

  void _openQASheet(Announcement announcement) {
    NotificationService().clearAnnouncementQACount(
      widget.groupId,
      announcement.id,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: AnnouncementQASheet(
          groupId: widget.groupId,
          announcementId: announcement.id,
          announcementTitle: announcement.title,
          isModOrAdmin: _isModOrAdmin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: PremiumLoadingIndicator());
    if (_group == null) return _emptyView('This group does not exist.');
    if (!_isMember) return _membersOnlyView();

    return Scaffold(
      floatingActionButton: _dynamicFAB(),
      body: SafeArea(
        child: Column(
          children: [
            _clubHeader(),
            const SizedBox(height: 16),
            _tabSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_announcementsTab(), _membersTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _dynamicFAB() {
    if (!_isModOrAdmin) return null;
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: _showPostAnnouncementDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Widget _clubHeader() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: colors.onSurface,
            iconSize: 20,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _group!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Announcements, members, and mild chaos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          _isAdmin ? _adminHeaderMenu() : _leaveButton(),
        ],
      ),
    );
  }

  Widget _leaveButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        onPressed: _leaveClub,
        tooltip: 'Leave Group',
      ),
    );
  }

  Widget _adminHeaderMenu() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: NotificationService().unreadCountStream,
      builder: (context, snapshot) {
        final count = NotificationService().unreadCounts['join_requests'] ?? 0;
        return PopupMenuButton<String>(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.more_vert_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              if (count > 0 && _isModOrAdmin)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onSelected: (value) {
            if (value == 'show_code') {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Join Code',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                                letterSpacing: 2.0,
                              ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: _group?.joinCode ?? ''),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard'),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _group?.joinCode ?? 'N/A',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 8.0,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tap to copy',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (value == 'regen') _regenerateJoinCode();
            if (value == 'requests') {
              Navigator.pushNamed(
                context,
                '/club/join-requests',
                arguments: widget.groupId,
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'show_code',
              child: Row(
                children: [
                  Icon(Icons.qr_code_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Show Join Code'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'regen',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Regenerate code'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'requests',
              child: Row(
                children: [
                  Icon(Icons.group_add_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Manage requests'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tabSelector() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: colors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: colors.primary,
          labelStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelColor: colors.onSurface.withOpacity(0.4),
          tabs: [
            Tab(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: NotificationService().unreadCountStream,
                builder: (context, snapshot) {
                  final unreadCount = NotificationService().getClubUnreadCount(
                    widget.groupId,
                  );
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text('Announcements'),
                      if (unreadCount > 0)
                        Positioned(
                          right: -8,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Tab(text: 'Members'),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _membersOnlyView() {
    return _emptyView('Members only. You\'re not on the list. Yet.');
  }

  Widget _announcementsTab() {
    return StreamBuilder<List<Announcement>>(
      stream: _groupService.getAnnouncements(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const PremiumLoadingIndicator();

        final announcements = snapshot.data ?? [];
        if (announcements.isEmpty) {
          return const Center(
            child: Text(
              'No announcements yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
          itemCount: announcements.length,
          itemBuilder: (context, i) => _buildAnnouncementCard(announcements[i]),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(announcement.authorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        String authorName = announcement.authorName;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          authorName = userData['displayName'] ?? announcement.authorName;
        }

        return AnnouncementCard(
          announcement: announcement,
          authorName: authorName,
          isAdmin: _isAdmin,
          isModOrAdmin: _isModOrAdmin,
          groupId: widget.groupId,
          onDelete: () =>
              _groupService.deleteAnnouncement(widget.groupId, announcement.id),
          onTogglePin: () => _groupService.toggleAnnouncementPin(
            widget.groupId,
            announcement.id,
            !announcement.isPinned,
          ),
          onOpenQA: () => _openQASheet(announcement),
        );
      },
    );
  }

  Widget _membersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 12),
          child: TextField(
            onChanged: (value) => setState(() => _memberSearchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _memberSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _memberSearchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<GroupMember>>(
            stream: _groupService.getGroupMembers(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const PremiumLoadingIndicator();

              final members = snapshot.data ?? [];
              final filteredMembers = members.where((member) {
                if (_memberSearchQuery.isEmpty) return true;
                final query = _memberSearchQuery.toLowerCase();
                return member.displayName.toLowerCase().contains(query) ||
                    member.email.toLowerCase().contains(query);
              }).toList();

              final sortedMembers = List<GroupMember>.from(filteredMembers)
                ..sort((a, b) {
                  int getRolePriority(MemberRole role) {
                    if (role == MemberRole.admin) return 0;
                    if (role == MemberRole.moderator) return 1;
                    return 2;
                  }

                  final aPriority = getRolePriority(a.role);
                  final bPriority = getRolePriority(b.role);
                  if (aPriority != bPriority)
                    return aPriority.compareTo(bPriority);
                  return a.displayName.toLowerCase().compareTo(
                    b.displayName.toLowerCase(),
                  );
                });

              if (sortedMembers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _memberSearchQuery.isEmpty
                            ? 'No members found'
                            : 'No members match "$_memberSearchQuery"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                itemCount: sortedMembers.length,
                itemBuilder: (context, i) => _memberTile(sortedMembers[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _memberTile(GroupMember member) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(member.userId).snapshots(),
      builder: (context, userSnapshot) {
        String displayName = member.displayName;
        String email = member.email;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['displayName'] ?? member.displayName;
          email = userData['email'] ?? member.email;
          if (displayName != member.displayName || email != member.email) {
            _syncMemberProfile(member);
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.08),
                radius: 20,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        if (member.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ADMIN',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        if (member.isMod)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'MOD',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isAdmin) _memberActions(member, displayName),
            ],
          ),
        );
      },
    );
  }

  Widget _memberActions(GroupMember member, String displayName) {
    final isOriginalAdmin =
        _group?.adminIds.isNotEmpty == true &&
        _group!.adminIds.first == member.userId;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        try {
          if (value == 'kick') {
            if (isOriginalAdmin)
              throw Exception('Cannot remove original admin');
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Remove Member?'),
                content: Text('Kick $displayName from the group?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Kick'),
                  ),
                ],
              ),
            );
            if (confirm == true)
              await _groupService.removeMember(widget.groupId, member.userId);
          } else if (value == 'make_mod') {
            await _groupService.makeModerator(widget.groupId, member.userId);
          } else if (value == 'remove_mod') {
            await _groupService.removeModerator(widget.groupId, member.userId);
          } else if (value == 'make_admin') {
            await _groupService.makeAdmin(widget.groupId, member.userId);
          } else if (value == 'remove_admin') {
            await _groupService.removeAdmin(widget.groupId, member.userId);
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action completed for $displayName')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      itemBuilder: (_) {
        final items = <PopupMenuEntry<String>>[];
        if (!isOriginalAdmin)
          items.add(const PopupMenuItem(value: 'kick', child: Text('Kick')));
        if (!member.isAdmin) {
          if (!member.isMod) {
            items.add(
              const PopupMenuItem(
                value: 'make_mod',
                child: Text('Make Moderator'),
              ),
            );
          } else {
            items.add(
              const PopupMenuItem(
                value: 'remove_mod',
                child: Text('Remove Moderator'),
              ),
            );
          }
        } else if (member.isMod && member.isAdmin) {
          items.add(
            const PopupMenuItem(
              value: 'remove_mod',
              child: Text('Remove Moderator'),
            ),
          );
        }
        if (_group != null &&
            _group!.adminIds.first == FirebaseAuth.instance.currentUser?.uid) {
          if (!member.isAdmin) {
            items.add(
              const PopupMenuItem(
                value: 'make_admin',
                child: Text('Make Admin'),
              ),
            );
          } else if (!isOriginalAdmin) {
            items.add(
              const PopupMenuItem(
                value: 'remove_admin',
                child: Text('Remove Admin'),
              ),
            );
          }
        }
        return items;
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// AnnouncementCard
// ---------------------------------------------------------------------------

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final String authorName;
  final bool isAdmin;
  final bool isModOrAdmin;
  final String groupId;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenQA;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.authorName,
    required this.isAdmin,
    required this.isModOrAdmin,
    required this.groupId,
    required this.onDelete,
    required this.onTogglePin,
    required this.onOpenQA,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final groupService = GroupService();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                ),
              Expanded(
                child: Text(
                  announcement.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: colors.onSurface.withOpacity(0.4),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                    if (value == 'toggle_pin') onTogglePin();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle_pin',
                      child: Row(
                        children: [
                          Icon(
                            announcement.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(announcement.isPinned ? 'Unpin' : 'Pin'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            announcement.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 14,
                color: colors.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                authorName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: colors.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(announcement.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.4),
                ),
              ),
              const Spacer(),
              if (isModOrAdmin)
                StreamBuilder<int>(
                  stream: groupService.getUnansweredQuestionCount(
                    groupId,
                    announcement.id,
                  ),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _qaButton(context, colors, count, announcement.id);
                  },
                )
              else
                _qaButton(context, colors, 0, announcement.id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qaButton(
    BuildContext context,
    ColorScheme colors,
    int unansweredCount,
    String announcementId,
  ) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: NotificationService().unreadCountStream,
      builder: (context, snapshot) {
        final hasUnread =
            NotificationService().getAnnouncementUnreadQACount(announcementId) >
            0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            TextButton.icon(
              onPressed: onOpenQA,
              icon: Icon(
                Icons.question_answer_rounded,
                size: 18,
                color: colors.primary,
              ),
              label: Text(
                'Ask',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: colors.primary.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            // Show either unanswered count (for staff) or red dot (for unread replies)
            if (unansweredCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unansweredCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (hasUnread)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0)
      return diff.inHours > 0
          ? '${diff.inHours}h ago'
          : '${diff.inMinutes}m ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
