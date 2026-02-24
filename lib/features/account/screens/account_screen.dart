import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/core/widgets/buttons/custom_secondary_button.dart';
import 'package:gr0ve/core/widgets/misc/custom_text_field.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/misc/not_logged_in.dart';
import 'package:gr0ve/features/authentication/services/authentication_service.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/core/widgets/dialogs/confirm_dialog.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onCustomizeNavigation;
  const AccountScreen({super.key, this.onCustomizeNavigation});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool loading = true;
  User? user;
  final AuthenticationService _authService = AuthenticationService();

  // User profile data
  bool isEmailVerified = false;
  bool isBergenStudent = false;
  String? userGrade;
  String? userAcademy;

  // Active counselor persona (reflected in the tile)
  CounselorPersona _activePersona = CounselorPersonaService.activePersona.value;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    FirebaseAnalytics.instance.logEvent(name: 'screen_account');

    // Keep persona tile in sync with global notifier
    CounselorPersonaService.activePersona.addListener(_onPersonaChanged);
  }

  @override
  void dispose() {
    CounselorPersonaService.activePersona.removeListener(_onPersonaChanged);
    super.dispose();
  }

  void _onPersonaChanged() {
    if (mounted) {
      setState(() {
        _activePersona = CounselorPersonaService.activePersona.value;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isEmailVerified = user!.emailVerified;
      final email = user!.email ?? '';
      isBergenStudent = email.endsWith('@bergen.org');

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          userGrade = data?['grade'];
          userAcademy = data?['academy'];
        }
      } catch (e) {
        debugPrint('Error loading user profile: $e');
      }
    }

    setState(() => loading = false);
  }

  String _getDisplayEmail() {
    if (user == null || user!.isAnonymous) return 'Guest Account';
    return user!.email ?? 'No email';
  }

  // ── Counselor persona picker ─────────────────────────────────
  Future<void> _showCounselorPicker() async {
    final brightness = Theme.of(context).brightness;
    CounselorPersona selected = _activePersona;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final colors = Theme.of(ctx).colorScheme;
          final textTheme = Theme.of(ctx).textTheme;
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Switch Counselor',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your counselor\'s color theme follows you across the app.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                ...CounselorPersona.values.map((persona) {
                  final isSelected = selected == persona;
                  final accent = persona.primary(brightness);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selected = persona),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withOpacity(0.08)
                              : colors.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? accent
                                : colors.outline.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(0.1),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  persona.avatarAsset(brightness),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        persona.displayName,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? accent
                                              : colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Specialty badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          persona.specialtyLabel,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    persona.tagline,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface.withOpacity(0.5),
                                      fontStyle: FontStyle.italic,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: accent,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await CounselorPersonaService.setPersona(selected);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected.primary(brightness),
                      foregroundColor: selected.onPrimary(brightness),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Switch to ${selected.displayName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Other handlers (unchanged) ───────────────────────────────

  Future<void> _sendVerificationEmail() async {
    if (user == null || user!.emailVerified) return;
    try {
      await user!.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
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

  Future<void> _updateGrade() async {
    if (!isBergenStudent) return;
    final grades = ['9', '10', '11', '12'];
    String? selectedGrade = userGrade;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Grade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: grades.map((grade) {
            return RadioListTile<String>(
              title: Text('Grade $grade'),
              value: grade,
              groupValue: selectedGrade,
              onChanged: (value) {
                selectedGrade = value;
                Navigator.pop(ctx, true);
              },
            );
          }).toList(),
        ),
        actions: [
          CustomSecondaryButton(
            label: 'Cancel',
            onTap: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );

    if (confirmed == true && selectedGrade != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'grade': selectedGrade});
        setState(() => userGrade = selectedGrade);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grade updated successfully'),
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
  }

  Future<void> _updateAcademy() async {
    if (!isBergenStudent) return;
    final academies = [
      'ATCS',
      'AAST',
      'ABF',
      'ACAHA',
      'AEDT',
      'AMST',
      'AVPA-A',
      'AVPA-M',
      'AVPA-T',
    ];
    String? selectedAcademy = userAcademy;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Academy'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: academies.length,
            itemBuilder: (context, index) {
              final academy = academies[index];
              return RadioListTile<String>(
                title: Text(academy),
                value: academy,
                groupValue: selectedAcademy,
                onChanged: (value) {
                  selectedAcademy = value;
                  Navigator.pop(ctx, true);
                },
              );
            },
          ),
        ),
        actions: [
          CustomSecondaryButton(
            label: 'Cancel',
            onTap: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );

    if (confirmed == true && selectedAcademy != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'academy': selectedAcademy});
        setState(() => userAcademy = selectedAcademy);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Academy updated successfully'),
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
  }

  Future<void> _updateNickname() async {
    String newNickname = user?.displayName ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your new display name'),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: 'Name',
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
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'displayName': newNickname.trim(),
      }, SetOptions(merge: true));
      await user!.updateDisplayName(newNickname.trim());
      await user!.reload();
      setState(() => user = FirebaseAuth.instance.currentUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated successfully'),
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

  Future<void> _resetPassword() async {
    if (user == null || user!.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset is not available for guest accounts'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final email = user!.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address found for this account'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A password reset link will be sent to your email address:',
            ),
            const SizedBox(height: 12),
            Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  label: 'Send Reset Email',
                  onTap: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
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
            if (!user!.isAnonymous) ...[
              const SizedBox(height: 20),
              CustomTextField(
                hintText: 'Enter your password to confirm',
                obscureText: true,
                controller: TextEditingController(),
                onChange: (val) => password = val,
              ),
            ],
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
    if (confirmed != true) return;
    if (!user!.isAnonymous && password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await _authService.deleteAccount(password);
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
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
    StarredBusService.reset();
    StarredTeacherService.reset();
    await _authService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // ── Build ────────────────────────────────────────────────────

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
              'Loading your account...',
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
        const CustomHeader(title: "ACCOUNT"),
        const SizedBox(height: 32),
        _buildAccountInformation(colors),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAccountInformation(ColorScheme colors) {
    final brightness = Theme.of(context).brightness;
    final personaColor = _activePersona.primary(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Account tiles ──────────────────────────────────────
        if (!user!.isAnonymous)
          _buildSettingsTile(
            icon: Icons.email_rounded,
            iconColor: colors.primary,
            title: 'Email',
            subtitle: _getDisplayEmail(),
            trailing: !isEmailVerified ? Icons.warning_rounded : null,
            trailingColor: Colors.orange,
            onTap: !isEmailVerified ? _sendVerificationEmail : () {},
          ),

        if (!user!.isAnonymous && !isEmailVerified) ...[
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.mark_email_unread_rounded,
            iconColor: Colors.orange,
            title: 'Verify Email',
            subtitle: 'Tap to send verification email',
            trailing: Icons.send_rounded,
            onTap: _sendVerificationEmail,
          ),
        ],

        _buildDivider(),

        _buildSettingsTile(
          icon: Icons.person_rounded,
          iconColor: colors.primary,
          title: 'Name',
          subtitle: user?.displayName ?? 'No name set',
          trailing: Icons.edit_rounded,
          onTap: _updateNickname,
        ),

        if (!user!.isAnonymous) ...[
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.lock_reset_rounded,
            iconColor: colors.primary,
            title: 'Password',
            subtitle: 'Send password reset email',
            trailing: Icons.email_rounded,
            onTap: _resetPassword,
          ),
        ],

        if (isBergenStudent) ...[
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.school_rounded,
            iconColor: colors.primary,
            title: 'Grade',
            subtitle: !isEmailVerified
                ? 'Please verify email to change'
                : (userGrade != null ? 'Grade $userGrade' : 'Tap to configure'),
            trailing: Icons.edit_rounded,
            onTap: isEmailVerified ? _updateGrade : null,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.apartment_rounded,
            iconColor: colors.primary,
            title: 'Academy',
            subtitle: !isEmailVerified
                ? 'Please verify email to change'
                : (userAcademy ?? 'Tap to configure'),
            trailing: Icons.edit_rounded,
            onTap: isEmailVerified ? _updateAcademy : null,
          ),
        ],

        _buildDivider(),

        _buildSettingsTile(
          icon: Icons.sort_rounded,
          iconColor: colors.primary,
          title: 'Customize Navigation',
          subtitle: 'Reorder items in your navigation bar',
          trailing: Icons.chevron_right_rounded,
          onTap: widget.onCustomizeNavigation,
        ),

        // ── Counselor / Theme section ──────────────────────────
        _buildSectionHeader('CHATBOT & THEME'),

        // Persona tile — shows avatar + name + color accent
        InkWell(
          onTap: _showCounselorPicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Icon container tinted with persona color
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: personaColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: personaColor.withOpacity(0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      _activePersona.avatarAsset(brightness),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Counselor & Theme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // Colored dot
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: personaColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            '${_activePersona.displayName} · ${_activePersona.specialtyLabel}',
                            style: TextStyle(
                              fontSize: 13,
                              color: personaColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),

        // ── Danger zone ────────────────────────────────────────
        _buildSectionHeader('ACCOUNT'),

        _buildSettingsTile(
          icon: Icons.logout_rounded,
          iconColor: colors.error,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          titleColor: colors.error,
          onTap: _logout,
        ),

        _buildDivider(),

        _buildSettingsTile(
          icon: Icons.delete_forever_rounded,
          iconColor: colors.error,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          titleColor: colors.error,
          onTap: _confirmDeleteAccount,
        ),
      ],
    );
  }

  /// Gray section header label (e.g. "CHATBOT & THEME")
  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    IconData? trailing,
    Color? titleColor,
    Color? trailingColor,
    required VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Icon(
                  trailing,
                  size: 20,
                  color: trailingColor ?? colors.onSurface.withOpacity(0.3),
                ),
            ],
          ),
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
