import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  const ClubDetailScreen({super.key, required this.groupId});

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

  // Cache for user profiles to reduce Firestore reads
  final Map<String, Map<String, dynamic>> _userProfileCache = {};

  // Add this as a state variable in your StatefulWidget
  String _memberSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadGroupData();

    // Clear notifications for this club when entering detail screen
    NotificationService().clearClubAnnouncementCount(widget.groupId);

    // Also clear when switching to announcements tab
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        // Announcements tab
        NotificationService().clearClubAnnouncementCount(widget.groupId);
      }
    });
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
      ).showSnackBar(SnackBar(content: Text('Error loading club: $e')));
    }
  }

  /// Get user profile from cache or Firestore
  Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    // Check cache first
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId]!;
    }

    // Fetch from Firestore
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final profile = userDoc.data()!;
        _userProfileCache[userId] = profile;
        return profile;
      }
    } catch (e) {
      // Fallback to empty profile
    }

    return {'displayName': 'Unknown', 'email': ''};
  }

  /// Sync member profile with latest user data
  Future<void> _syncMemberProfile(GroupMember member) async {
    final profile = await _getUserProfile(member.userId);
    final latestName = profile['displayName'] ?? member.displayName;
    final latestEmail = profile['email'] ?? member.email;

    // Only update if there's a difference
    if (latestName != member.displayName || latestEmail != member.email) {
      try {
        await _firestore
            .collection('groups')
            .doc(widget.groupId)
            .collection('members')
            .doc(member.userId)
            .update({'displayName': latestName, 'email': latestEmail});
      } catch (e) {
        // Silently fail - not critical
      }
    }
  }

  Future<void> _regenerateJoinCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Regenerate Join Code?'),
        content: const Text(
          'This will invalidate the current join code. Members already in the club will not be affected.',
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
        title: const Text('Leave Club?'),
        content: const Text('Are you sure you want to leave this club?'),
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
      ).showSnackBar(const SnackBar(content: Text('Left club successfully')));
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: PremiumLoadingIndicator());
    if (_group == null) return _emptyView('This club does not exist.');
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
    // Moderators and admins can post announcements
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
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 12),
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
        tooltip: 'Leave Club',
      ),
    );
  }

  Widget _adminHeaderMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _group?.joinCode ?? ''));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _group?.joinCode ?? 'N/A',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8.0,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tap to copy',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
          labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelColor: colors.onSurface.withOpacity(0.4),
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'Members'),
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
    return _emptyView('Members only You\'re not on the list. Yet.');
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
    // Use StreamBuilder to get real-time user profile updates
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(announcement.authorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        String authorName = announcement.authorName;

        // Update author name if we have fresh data from user profile
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          authorName = userData['displayName'] ?? announcement.authorName;
        }

        return AnnouncementCard(
          announcement: announcement,
          authorName: authorName, // Use real-time author name
          isAdmin: _isAdmin,
          onDelete: () =>
              _groupService.deleteAnnouncement(widget.groupId, announcement.id),
          onTogglePin: () => _groupService.toggleAnnouncementPin(
            widget.groupId,
            announcement.id,
            !announcement.isPinned,
          ),
        );
      },
    );
  }

  Widget _membersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 12),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _memberSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _memberSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _memberSearchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

        // Members list
        Expanded(
          child: StreamBuilder<List<GroupMember>>(
            stream: _groupService.getGroupMembers(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const PremiumLoadingIndicator();

              final members = snapshot.data ?? [];

              // Filter members based on search query
              final filteredMembers = members.where((member) {
                if (_memberSearchQuery.isEmpty) return true;
                final query = _memberSearchQuery.toLowerCase();
                return member.displayName.toLowerCase().contains(query) ||
                    member.email.toLowerCase().contains(query);
              }).toList();

              // Sort members: ADMIN first, then MODERATOR, then alphabetically
              final sortedMembers = List<GroupMember>.from(filteredMembers)
                ..sort((a, b) {
                  // Define role priority: admin = 0, moderator = 1, member = 2
                  int getRolePriority(MemberRole role) {
                    if (role == MemberRole.admin) return 0;
                    if (role == MemberRole.moderator) return 1;
                    return 2;
                  }

                  final aPriority = getRolePriority(a.role);
                  final bPriority = getRolePriority(b.role);

                  // If roles are different, sort by priority
                  if (aPriority != bPriority) {
                    return aPriority.compareTo(bPriority);
                  }

                  // If same role, sort alphabetically by displayName (case-insensitive)
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
    // Use StreamBuilder to get real-time user profile updates
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(member.userId).snapshots(),
      builder: (context, userSnapshot) {
        String displayName = member.displayName;
        String email = member.email;

        // Update with fresh data if available
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['displayName'] ?? member.displayName;
          email = userData['email'] ?? member.email;

          // Sync the member profile in the background if changed
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
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (member.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ADMIN',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (member.isMod)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'MOD',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                content: Text('Kick $displayName from the club?'),
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

        // Kick option - available for non-original-admin members
        if (!isOriginalAdmin)
          items.add(const PopupMenuItem(value: 'kick', child: Text('Kick')));

        // Moderator options
        if (!member.isAdmin) {
          // Can make moderator if they're not already
          if (!member.isMod) {
            items.add(
              const PopupMenuItem(
                value: 'make_mod',
                child: Text('Make Moderator'),
              ),
            );
          } else {
            // Can remove moderator status
            items.add(
              const PopupMenuItem(
                value: 'remove_mod',
                child: Text('Remove Moderator'),
              ),
            );
          }
        } else if (member.isMod && member.isAdmin) {
          // Admin who is also a mod - can remove mod status
          items.add(
            const PopupMenuItem(
              value: 'remove_mod',
              child: Text('Remove Moderator'),
            ),
          );
        }

        // Admin options - only original admin can manage other admins
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

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final String authorName; // Real-time author name
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.authorName,
    required this.isAdmin,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
                  child: Icon(Icons.push_pin_rounded, size: 16, color: colors.primary),
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
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.onSurface.withOpacity(0.4)),
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
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text('Delete', style: TextStyle(color: Colors.red)),
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
              Icon(Icons.person_rounded, size: 14, color: colors.onSurface.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(
                authorName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time_rounded, size: 14, color: colors.onSurface.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(
                _formatDate(announcement.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
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
