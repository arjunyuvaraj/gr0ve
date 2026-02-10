import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/components/custom_secondary_button.dart';
import 'package:gr0ve/components/custom_text_field.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/components/empty_link_dialog.dart';
import 'package:gr0ve/components/not_logged_in.dart';
import 'package:gr0ve/services/authentication_service.dart';
import 'package:gr0ve/services/link_service.dart';
import 'package:gr0ve/services/starred_bus_service.dart';
import 'package:gr0ve/services/starred_teacher_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gr0ve/core/utilities/extensions/string_extensions.dart';
// Import the new components
import 'package:gr0ve/components/user_card.dart';
import 'package:gr0ve/components/link_card.dart';
import 'package:gr0ve/components/add_link_dialog.dart';
import 'package:gr0ve/components/confirm_dialog.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool loading = true;
  bool isReordering = false;
  List<QuickLink> links = [];
  User? user;
  static const int maxLinks = 10;

  @override
  void initState() {
    super.initState();
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

  Future<void> _updateNickname() async {
    String newNickname = user?.displayName ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Nickname'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your new display name'),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: 'Nickname',
              controller: TextEditingController(text: newNickname),
              onChange: (val) => newNickname = val,
              obscureText: false,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomSecondaryButton(
                  label: 'Cancel',
                  onTap: () => Navigator.pop(ctx, false),
                ),
                const SizedBox(height: 12),
                CustomPrimaryButton(
                  label: 'Update',
                  onTap: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || newNickname.trim().isEmpty) return;

    try {
      if (user == null) return;
      FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'displayName': newNickname.trim(),
      }, SetOptions(merge: true));
      await user!.updateDisplayName(newNickname.trim());
      await user!.reload();

      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nickname updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (user == null) return;

    if (user!.isAnonymous) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => ConfirmDialog(
          title: 'Delete Account',
          message:
              'Are you sure you want to delete your guest account? This cannot be undone.',
          confirmLabel: 'Delete',
          isDangerous: true,
        ),
      );

      if (confirmed != true) return;

      try {
        await AuthenticationService().deleteAccount();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    } else {
      await _deleteAccountWithPassword();
    }
  }

  Future<void> _deleteAccountWithPassword() async {
    String password = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: 'Enter your password to confirm',
              obscureText: true,
              controller: TextEditingController(),
              onChange: (val) => password = val,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomSecondaryButton(
                  label: 'Cancel',
                  onTap: () => Navigator.pop(ctx, false),
                ),
                const SizedBox(height: 12),
                CustomPrimaryButton(
                  label: 'Delete Account',
                  onTap: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || password.trim().isEmpty) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user!.reauthenticateWithCredential(credential);
      await AuthenticationService().deleteAccount();

      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? 'Authentication failed'}'),
          ),
        );
      }
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: 'Logout',
        message: 'Are you sure you want to logout?',
        confirmLabel: 'Logout',
      ),
    );

    if (confirmed != true) return;

    // Reset services BEFORE signing out to prevent permission errors
    StarredBusService.reset();
    StarredTeacherService.reset();

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
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
              'Loading your gr0ve...',
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

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomHeader(
                    title: "ACCOUNT",
                    subtitle: "Manage your info and favorite links",
                  ),
                  const SizedBox(height: 12),
                  UserCard(
                    user: user!,
                    onAddLink: _addLink,
                    onLogout: _logout,
                    onDeleteAccount: _confirmDeleteAccount,
                    onUpdateNickname: _updateNickname,
                  ),

                  // Reorder button
                  if (links.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton.icon(
                        onPressed: _toggleReordering,
                        icon: Icon(
                          isReordering ? Icons.check : Icons.swap_vert,
                          size: 20,
                        ),
                        label: Text(
                          isReordering
                              ? 'Done Reordering'.capitalized
                              : 'Reorder Links'.capitalized,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildLinksGrid(theme, colors),
        ],
      ),
    );
  }

  Widget _buildLinksGrid(ThemeData theme, ColorScheme colors) {
    if (links.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyLinksView(),
      );
    }

    if (isReordering) {
      // Use ReorderableListView when in reorder mode
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderLinks,
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return Padding(
                key: ValueKey(link.id),
                padding: const EdgeInsets.only(bottom: 16),
                child: LinkCard(
                  link: link,
                  onTap: () {},
                  onRemove: () => _removeLink(link),
                  isReordering: true,
                ),
              );
            },
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          int columns = 1;
          if (constraints.crossAxisExtent > 900) {
            columns = 3;
          } else if (constraints.crossAxisExtent > 600) {
            columns = 2;
          }

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final link = links[index];
              return LinkCard(
                link: link,
                onTap: () => _openLink(link),
                onRemove: () => _removeLink(link),
                onEdit: () => _editLink(link),
                isReordering: false,
              );
            }, childCount: links.length),
          );
        },
      ),
    );
  }
}
