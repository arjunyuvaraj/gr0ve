import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/social/services/social_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';
import 'package:gr0ve/core/widgets/misc/custom_text_field.dart';
import 'package:gr0ve/core/widgets/misc/premium_avatar.dart';

class SocialSearchSheet extends StatefulWidget {
  const SocialSearchSheet({super.key});

  @override
  State<SocialSearchSheet> createState() => _SocialSearchSheetState();
}

class _SocialSearchSheetState extends State<SocialSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  void _onSearch(String val) async {
    if (val.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await SocialService.searchUsers(val);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withAlpha(25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Find Friends',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for people to see what they\'re up to!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            hintText: 'Search by name...',
            controller: _searchController,
            onChange: _onSearch,
            obscureText: false,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: PremiumLoadingIndicator())
                : _results.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: colors.onSurface.withAlpha(100)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final user = _results[i];
                          return _UserTile(user: user);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatefulWidget {
  final Map<String, dynamic> user;
  const _UserTile({required this.user});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    // In a real app, check if already following. For now, assume not.
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = widget.user['displayName'] ?? 'User';
    final email = widget.user['email'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withAlpha(20)),
      ),
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: widget.user['active_profile_picture'],
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              SocialService.followUser(widget.user['uid']);
              setState(() => _isFollowing = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? colors.surface : colors.primary,
              foregroundColor: _isFollowing ? colors.primary : colors.surface,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: _isFollowing
                    ? BorderSide(color: colors.primary)
                    : BorderSide.none,
              ),
            ),
            child: Text(_isFollowing ? 'Requested' : 'Add Friend'),
          ),
        ],
      ),
    );
  }
}
