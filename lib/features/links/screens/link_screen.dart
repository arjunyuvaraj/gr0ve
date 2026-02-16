import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/misc/not_logged_in.dart';
import 'package:gr0ve/features/links/service/link_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gr0ve/features/links/widgets/add_link_dialog.dart';
import 'package:gr0ve/core/widgets/dialogs/confirm_dialog.dart';

class LinksScreen extends StatefulWidget {
  const LinksScreen({super.key});

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> {
  bool loading = true;
  bool isReordering = false;
  List<QuickLink> links = [];
  User? user;
  static const int maxLinks = 10;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'screen_links');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);
    user = FirebaseAuth.instance.currentUser;
    final userLinks = await LinkService.getUserLinks();
    setState(() {
      links = List<QuickLink>.from(userLinks);
      loading = false;
    });
  }

  Future<void> _editLink(QuickLink link) async {
    await showDialog(
      context: context,
      builder: (ctx) => AddLinkDialog(
        editingLink: link,
        onAdd: (String title, String url, String iconKey, Color color) {
          final updatedLink = QuickLink(
            id: link.id,
            title: title,
            url: url,
            iconKey: iconKey,
            color: color,
          );

          setState(() {
            final index = links.indexWhere((l) => l.id == link.id);
            if (index != -1) {
              links[index] = updatedLink;
            }
          });

          LinkService.saveUserLinks(links);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _toggleReordering() {
    setState(() {
      isReordering = !isReordering;
    });

    if (!isReordering) {
      // Save the new order when exiting reorder mode
      LinkService.saveUserLinks(links);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link order saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _reorderLinks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = links.removeAt(oldIndex);
      links.insert(newIndex, item);
    });
  }

  Future<void> _removeLink(QuickLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: 'Remove Link',
        message: 'Are you sure you want to remove "${link.title}"?',
        confirmLabel: 'Remove',
      ),
    );

    if (confirmed != true) return;

    setState(() {
      links = List<QuickLink>.from(links)..removeWhere((l) => l.id == link.id);
    });
    await LinkService.saveUserLinks(links);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addLink() async {
    if (links.length >= maxLinks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Maximum of $maxLinks links reached"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AddLinkDialog(
        onAdd: (String title, String url, String iconKey, Color color) {
          final newLink = QuickLink(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            url: url,
            iconKey: iconKey,
            color: color,
          );

          setState(() {
            links.add(newLink);
          });

          LinkService.saveUserLinks(links);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link added successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openLink(QuickLink link) async {
    try {
      if (link.url.startsWith("/")) {
        Navigator.pushNamed(context, link.url);
      } else {
        final uri = Uri.parse(link.url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading your links...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (user == null) {
      return NotLoggedIn(
        onSignIn: () => Navigator.pushReplacementNamed(context, '/login'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const CustomHeader(title: "LINKS"),
        const SizedBox(height: 32),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_rounded,
                  label: 'Add Link',
                  onTap: _addLink,
                  colors: colors,
                ),
              ),
              if (links.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: isReordering
                        ? Icons.check_rounded
                        : Icons.swap_vert_rounded,
                    label: isReordering ? 'Done' : 'Reorder',
                    onTap: _toggleReordering,
                    colors: colors,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (links.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${links.length}/$maxLinks links',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Links List
        if (links.isEmpty)
          _buildEmptyState(colors, theme)
        else if (isReordering)
          _buildReorderableList()
        else
          _buildLinksList(),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.link_off_rounded,
              size: 48,
              color: colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No links yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first quick link to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _reorderLinks,
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        return Column(
          key: ValueKey(link.id),
          children: [
            _buildLinkTile(link, isReordering: true),
            if (index < links.length - 1) _buildDivider(),
          ],
        );
      },
    );
  }

  Widget _buildLinksList() {
    return Column(
      children: [
        for (int i = 0; i < links.length; i++) ...[
          _buildLinkTile(links[i]),
          if (i < links.length - 1) _buildDivider(),
        ],
      ],
    );
  }

  Widget _buildLinkTile(QuickLink link, {bool isReordering = false}) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isReordering ? null : () => _openLink(link),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: link.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(link.icon, size: 22, color: link.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link.url,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isReordering)
              Icon(
                Icons.drag_handle_rounded,
                size: 24,
                color: colors.onSurface.withOpacity(0.3),
              )
            else ...[
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: colors.onSurface.withOpacity(0.5),
                ),
                onPressed: () => _editLink(link),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: colors.error.withOpacity(0.7),
                ),
                onPressed: () => _removeLink(link),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
      ),
    );
  }
}
