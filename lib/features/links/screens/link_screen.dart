import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/misc/not_logged_in.dart';
import 'package:gr0ve/features/links/service/link_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gr0ve/features/links/widgets/add_link_dialog.dart';
import 'package:gr0ve/core/widgets/dialogs/confirm_dialog.dart';
import 'package:hugeicons/hugeicons.dart';

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
      padding: const EdgeInsets.only(top: 24, bottom: 110),
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
                  icon: HugeIcons.strokeRoundedAdd01,
                  label: 'Add Link',
                  onTap: _addLink,
                  colors: colors,
                  isPrimary: true,
                ),
              ),
              if (links.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: isReordering
                        ? HugeIcons.strokeRoundedTick02
                        : HugeIcons.strokeRoundedArrangeByNumbers19,
                    label: isReordering ? 'Done' : 'Reorder',
                    onTap: _toggleReordering,
                    colors: colors,
                    isPrimary: false,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (links.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${links.length} / $maxLinks',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withOpacity(0.4),
                    letterSpacing: 0.3,
                  ),
                ),
                if (links.length == maxLinks) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'FULL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colors.onErrorContainer,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Links List
        if (links.isEmpty)
          _buildEmptyState(colors, theme)
        else if (isReordering)
          _buildReorderableList()
        else
          _buildLinksList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButton({
    required List<List<dynamic>> icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colors,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary
          ? colors.primary.withAlpha(150)
          : colors.surfaceContainerHighest.withOpacity(0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: isPrimary ? colors.onPrimary : colors.onSurface,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? colors.onPrimary : colors.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedLinkSquare02,
                size: 42,
                color: colors.onSurface.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Quick Links Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your favorite websites and shortcuts\nfor quick access anytime',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.5),
                height: 1.4,
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
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 8,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final link = links[index];
        return Padding(
          key: ValueKey(link.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLinkCard(link, isReordering: true),
        );
      },
    );
  }

  Widget _buildLinksList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: links.length,
        itemBuilder: (context, index) => _buildLinkGridCard(links[index]),
      ),
    );
  }

  Widget _buildLinkGridCard(QuickLink link) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLink(link),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outline.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: link.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(link.icon, size: 22, color: link.color),
                ),
              ),
              const SizedBox(height: 10),
              // Centered Title
              Text(
                link.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIconButton(
                    icon: HugeIcons.strokeRoundedEdit02,
                    color: colors.onSurface.withOpacity(0.2),
                    onPressed: () => _editLink(link),
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: colors.error.withOpacity(0.3),
                    onPressed: () => _removeLink(link),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkCard(QuickLink link, {bool isReordering = false}) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: isReordering
          ? const EdgeInsets.symmetric(horizontal: 20)
          : EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReordering ? null : () => _openLink(link),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: link.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(link.icon, size: 24, color: link.color),
                  ),
                ),
                const SizedBox(width: 14),

                // Title (with ellipsis truncation)
                Expanded(
                  child: Text(
                    link.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),

                // Action buttons
                if (isReordering)
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMenu11,
                    size: 22,
                    color: colors.onSurface.withOpacity(0.4),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconButton(
                        icon: HugeIcons.strokeRoundedEdit02,
                        color: colors.onSurface.withOpacity(0.5),
                        onPressed: () => _editLink(link),
                      ),
                      const SizedBox(width: 2),
                      _buildIconButton(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: colors.error.withOpacity(0.7),
                        onPressed: () => _removeLink(link),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required List<List<dynamic>> icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: HugeIcon(icon: icon, size: 20, color: color),
        ),
      ),
    );
  }
}
