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
import 'package:url_launcher/url_launcher.dart';

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
        onAdd: (title, url, icon, color) {
          final newLink = QuickLink(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            url: url,
            icon: icon,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomHeader(
                    title: "ACCOUNT",
                    subtitle: "Manage your info and favorite links",
                  ),
                  const SizedBox(height: 20),
                  UserCard(
                    user: user!,
                    onAddLink: _addLink,
                    onLogout: _logout,
                    onDeleteAccount: _confirmDeleteAccount,
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
              );
            }, childCount: links.length),
          );
        },
      ),
    );
  }
}
