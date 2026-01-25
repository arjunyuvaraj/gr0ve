import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/post_announcement_dialog.dart';
import '../services/group_service.dart';
import '../models/group.dart';
import '../models/announcement.dart';
import '../models/group_member.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadGroupData();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            const SizedBox(height: 12),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _group!.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Announcements, members, and mild chaos',
                  style: TextStyle(color: Colors.grey.shade600),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _leaveClub,
      child: const Text(
        'Leave',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _adminHeaderMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'show_code') {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Join Code'),
              content: SelectableText(_group?.joinCode ?? 'N/A'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
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
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'show_code', child: Text('Show Join Code')),
        PopupMenuItem(value: 'regen', child: Text('Regenerate code')),
        PopupMenuItem(value: 'requests', child: Text('Manage requests')),
      ],
    );
  }

  Widget _tabSelector() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          indicator: BoxDecoration(
            color: colors.primary.withAlpha(28),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withAlpha(140),
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
          return const Center(child: CircularProgressIndicator());

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
          padding: const EdgeInsets.all(16),
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

  // Add this as a state variable in your StatefulWidget
  String _memberSearchQuery = '';

  Widget _membersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _memberSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _memberSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _memberSearchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(128),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(128),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
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
                return const Center(child: CircularProgressIndicator());

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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(displayName)),
                if (member.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                if (member.isMod)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MOD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(email),
            trailing: _isAdmin ? _memberActions(member, displayName) : null,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (announcement.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.push_pin, size: 16, color: Colors.blue),
                  ),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton<String>(
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
                                  : Icons.push_pin,
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
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(announcement.content, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  authorName, // Use real-time author name
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(announcement.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
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
