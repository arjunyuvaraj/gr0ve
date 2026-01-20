import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TabController _tabController;

  Group? _group;
  bool _isAdmin = false;
  bool _isMember = false;
  bool _isLoading = true;

  static const primaryGreen = Color(0xFF2D6A4F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {})); // dynamic FAB
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final group = await _groupService.getGroup(widget.groupId);
      final isAdmin = await _groupService.isGroupAdmin(widget.groupId);
      final isMember = await _groupService.isGroupMember(widget.groupId);

      if (!mounted) return;
      setState(() {
        _group = group;
        _isAdmin = isAdmin;
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

  // ---------------------- HEADER ACTIONS ----------------------

  Future<void> _copyJoinCode() async {
    if (_group == null) return;
    await Clipboard.setData(ClipboardData(text: _group!.joinCode));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Join code copied')));
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

  // ---------------------- UI ----------------------

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

  // ---------------------- FAB ----------------------

  Widget? _dynamicFAB() {
    if (!_isAdmin) return null;
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: _showPostAnnouncementDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  // ---------------------- HEADER ----------------------
  // ---------------------- HEADER ----------------------

  Widget _clubHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: 4),

          // Title & subtitle
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

          // Admin menu or leave button
          _isAdmin ? _adminHeaderMenu() : _leaveButton(),
        ],
      ),
    );
  }

  // ---------------------- LEAVE BUTTON ----------------------
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
          // Show dialog with join code
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

  // ---------------------- TABS ----------------------
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
    return _emptyView('Members only\nYou’re not on the list. Yet.');
  }

  // ---------------------- ANNOUNCEMENTS ----------------------

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
          itemBuilder: (context, i) => AnnouncementCard(
            announcement: announcements[i],
            isAdmin: _isAdmin,
            onDelete: () => _groupService.deleteAnnouncement(
              widget.groupId,
              announcements[i].id,
            ),
            onTogglePin: () => _groupService.toggleAnnouncementPin(
              widget.groupId,
              announcements[i].id,
              !announcements[i].isPinned,
            ),
          ),
        );
      },
    );
  }

  // ---------------------- MEMBERS ----------------------

  Widget _membersTab() {
    return StreamBuilder<List<GroupMember>>(
      stream: _groupService.getGroupMembers(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final members = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, i) => _memberTile(members[i]),
        );
      },
    );
  }

  Widget _memberTile(GroupMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(member.displayName[0].toUpperCase())),
        title: Row(
          children: [
            Expanded(child: Text(member.displayName)),
            if (member.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        subtitle: Text(member.email),
        trailing: _isAdmin ? _memberActions(member) : null,
      ),
    );
  }

  Widget _memberActions(GroupMember member) {
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
                content: Text('Kick ${member.displayName} from the club?'),
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
            SnackBar(
              content: Text('Action completed for ${member.displayName}'),
            ),
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
          items.add(
            const PopupMenuItem(
              value: 'make_mod',
              child: Text('Make Moderator'),
            ),
          );
        } else if (member.isMod) {
          items.add(
            const PopupMenuItem(
              value: 'remove_mod',
              child: Text('Remove Moderator'),
            ),
          );
        }
        if (_group != null &&
            _group!.adminIds.first == FirebaseAuth.instance.currentUser?.uid) {
          if (!member.isAdmin)
            items.add(
              const PopupMenuItem(
                value: 'make_admin',
                child: Text('Make Admin'),
              ),
            );
          else if (!isOriginalAdmin)
            items.add(
              const PopupMenuItem(
                value: 'remove_admin',
                child: Text('Remove Admin'),
              ),
            );
        }
        return items;
      },
    );
  }

  // ---------------------- UTIL ----------------------

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

// ---------------------- ANNOUNCEMENT CARD ----------------------

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const AnnouncementCard({
    super.key,
    required this.announcement,
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
                  announcement.authorName,
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
