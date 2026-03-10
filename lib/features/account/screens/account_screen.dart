import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/core/widgets/buttons/custom_secondary_button.dart';
import 'package:gr0ve/core/widgets/misc/custom_text_field.dart';
import 'package:gr0ve/core/widgets/misc/not_logged_in.dart';
import 'package:gr0ve/features/account/screens/profile_picture_picker_sheet.dart';
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/features/authentication/services/authentication_service.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/legal/legal.dart';
import 'package:gr0ve/legal/terms_screen.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/core/widgets/dialogs/confirm_dialog.dart';
import 'package:gr0ve/features/counselor/screens/counselor_persona_picker.dart';
import 'package:gr0ve/features/easter_eggs/cedite_screen.dart';
import 'package:gr0ve/features/social/services/social_service.dart';
import 'package:gr0ve/features/social/screens/social_search_sheet.dart';

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
  ProfileVariant _activeVariant = ProfilePictureService.activeVariant.value;

  bool isEmailVerified = false;
  bool isBergenStudent = false;
  String? userGrade;
  String? userAcademy;

  CounselorPersona _activePersona = CounselorPersonaService.activePersona.value;

  int _counselorTapCount = 0;
  DateTime? _firstTapTime;
  static const _requiredTaps = 6;
  static const _tapWindow = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ProfilePictureService.activeVariant.addListener(_onVariantChanged);
    FirebaseAnalytics.instance.logEvent(name: 'screen_account');
    CounselorPersonaService.activePersona.addListener(_onPersonaChanged);
  }

  @override
  void dispose() {
    CounselorPersonaService.activePersona.removeListener(_onPersonaChanged);
    ProfilePictureService.activeVariant.removeListener(_onVariantChanged);
    super.dispose();
  }

  void _onVariantChanged() {
    if (mounted)
      setState(
        () => _activeVariant = ProfilePictureService.activeVariant.value,
      );
  }

  void _onPersonaChanged() {
    if (mounted) {
      setState(() {
        _activePersona = CounselorPersonaService.activePersona.value;
        _counselorTapCount = 0;
        _firstTapTime = null;
      });
    }
  }

  void _onCounselorAvatarTap() {
    if (CounselorPersonaService.cediteUnlocked) {
      _showCounselorPicker();
      return;
    }
    final now = DateTime.now();
    if (_firstTapTime != null && now.difference(_firstTapTime!) > _tapWindow) {
      _counselorTapCount = 0;
      _firstTapTime = null;
    }
    _firstTapTime ??= now;
    _counselorTapCount++;
    if (_counselorTapCount >= _requiredTaps) {
      _counselorTapCount = 0;
      _firstTapTime = null;
      _openCediteScreen();
    }
  }

  void _openCediteScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, _) => CediteScreen(
          onUnlocked: () {
            // CounselorPersonaService.markCediteUnlocked();
            if (Navigator.canPop(ctx)) Navigator.pop(ctx);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _offerSwitchToCedite();
            });
          },
        ),
        transitionsBuilder: (ctx, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _offerSwitchToCedite() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.cedite.primary(brightness);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: pc.withAlpha(38)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                CounselorPersona.cedite.avatarAsset(brightness),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cedite is available.',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "He was already here.\nHe's been waiting for you to notice.",
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withAlpha(102),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify what he tells you.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: pc.withAlpha(140),
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.outline.withAlpha(51)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Later',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onSurface.withAlpha(102),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await CounselorPersonaService.setPersona(
                        CounselorPersona.cedite,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pc,
                      foregroundColor: CounselorPersona.cedite.onPrimary(
                        brightness,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Speak with Cedite',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Future<void> _showCounselorPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PersonaPickerSheet(
        currentPersona: _activePersona,
        isChange: true,
        onSelect: (persona) async {
          await CounselorPersonaService.setPersona(persona);
        },
      ),
    );
  }

  Future<void> _showProfilePicturePicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProfilePicturePickerSheet(),
    );
  }

  Future<void> _sendVerificationEmail() async {
    if (user == null || user!.emailVerified) return;
    try {
      await user!.sendEmailVerification();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          children: grades
              .map(
                (grade) => RadioListTile<String>(
                  title: Text('Grade $grade'),
                  value: grade,
                  groupValue: selectedGrade,
                  onChanged: (value) {
                    selectedGrade = value;
                    Navigator.pop(ctx, true);
                  },
                ),
              )
              .toList(),
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grade updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
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
            itemBuilder: (context, index) => RadioListTile<String>(
              title: Text(academies[index]),
              value: academies[index],
              groupValue: selectedAcademy,
              onChanged: (value) {
                selectedAcademy = value;
                Navigator.pop(ctx, true);
              },
            ),
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Academy updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      if (mounted)
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

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

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
                color: colors.onSurface.withAlpha(153),
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

    final personaColor = _activePersona.primary(brightness);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(colors, brightness, isDark, personaColor, theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 32, 0),
            child: Column(
              children: [
                _buildBody(colors, brightness, isDark, personaColor),
                const SizedBox(
                  height: 120,
                ), // ADDED: Bottom padding for nav bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────────

  Widget _buildHero(
    ColorScheme colors,
    Brightness brightness,
    bool isDark,
    Color personaColor,
    ThemeData theme,
  ) {
    const double avatarSize = 86.0;
    const double bannerHeight = 150.0;
    const double overhang = avatarSize / 2;
    // Extra space below banner for avatar overhang + name text
    const double belowBannerHeight = overhang + 52.0;

    return SizedBox(
      height: bannerHeight + belowBannerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Banner — now truly edge-to-edge ──
          Container(
            width: double.infinity,
            height: bannerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  personaColor.withAlpha(isDark ? 140 : 97),
                  personaColor.withAlpha(isDark ? 25 : 13),
                ],
              ),
            ),
          ),

          // ── Avatar ─────────────────────────────────────────────
          Positioned(
            top: bannerHeight - overhang,
            left: 16, // Aligned with the body content padding
            child: GestureDetector(
              onTap: _showProfilePicturePicker,
              child: Stack(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: personaColor, width: 3),
                      color: colors.surface,
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 4,
                    child: ClipOval(
                      child: Image.asset(
                        _activeVariant.assetPath(brightness),
                        width: avatarSize - 8,
                        height: avatarSize - 8,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: avatarSize - 8,
                          height: avatarSize - 8,
                          color: personaColor.withAlpha(38),
                          child: Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: personaColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Camera badge
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: personaColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Name + email — right of avatar, constrained so it
          //    never overflows the available row width ──────────
          Positioned(
            top: bannerHeight + 8,
            left: avatarSize + 28,
            // Keep right edge within our content area (no bleed here)
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'No name set',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getDisplayEmail(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withAlpha(97),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────────────────────

  Widget _buildBody(
    ColorScheme colors,
    Brightness brightness,
    bool isDark,
    Color personaColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Email verification banner ──────────────────────────
          if (!isEmailVerified && !user!.isAnonymous) ...[
            GestureDetector(
              onTap: _sendVerificationEmail,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha(64)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email not verified — tap to resend',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: Colors.orange.withAlpha(128),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Student info chips ─────────────────────────────────
          if (isBergenStudent) ...[
            _sectionLabel('STUDENT INFO'),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(
                  colors: colors,
                  personaColor: personaColor,
                  icon: Icons.school_rounded,
                  label: userGrade != null ? 'Grade $userGrade' : 'Set grade',
                  onTap: isEmailVerified ? _updateGrade : null,
                  locked: !isEmailVerified,
                ),
                const SizedBox(width: 8),
                _infoChip(
                  colors: colors,
                  personaColor: personaColor,
                  icon: Icons.apartment_rounded,
                  label: userAcademy ?? 'Set academy',
                  onTap: isEmailVerified ? _updateAcademy : null,
                  locked: !isEmailVerified,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── Chatbot & appearance group ─────────────────────────
          _sectionLabel('CHATBOT & APPEARANCE'),
          const SizedBox(height: 8),
          _buildGroup(
            borderColor: colors.outline.withAlpha(18),
            bgColor: colors.surfaceVariant.withAlpha(isDark ? 89 : 115),
            children: [
              _counselorRow(colors, brightness, personaColor, isDark),
              _divider(colors),
              _settingsRow(
                leadingWidget: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _activeVariant.assetPath(brightness),
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: personaColor.withAlpha(25),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: personaColor,
                      ),
                    ),
                  ),
                ),
                label: 'Profile Picture',
                value: _activeVariant.displayName,
                onTap: _showProfilePicturePicker,
                colors: colors,
              ),
            ],
          ),

          // ── Friends section — Lightweight social ────────────────
          if (!user!.isAnonymous) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('FRIENDS'),
                GestureDetector(
                  onTap: _showSocialSearch,
                  child: Text(
                    'FIND PEOPLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFriendsList(colors, personaColor),
          ],
          const SizedBox(height: 20),
          _sectionLabel('SETTINGS'),
          const SizedBox(height: 8),
          _buildGroup(
            borderColor: colors.outline.withAlpha(18),
            bgColor: colors.surfaceVariant.withAlpha(isDark ? 89 : 115),
            children: [
              if (!user!.isAnonymous) ...[
                _settingsRow(
                  icon: Icons.person_rounded,
                  iconColor: colors.primary,
                  label: 'Name',
                  value: user?.displayName ?? 'No name set',
                  onTap: _updateNickname,
                  colors: colors,
                ),
                _divider(colors),
                _settingsRow(
                  icon: Icons.lock_reset_rounded,
                  iconColor: colors.primary,
                  label: 'Password',
                  value: 'Reset via email',
                  onTap: _resetPassword,
                  colors: colors,
                ),
                _divider(colors),
                _settingsRow(
                  icon: Icons.description_outlined,
                  iconColor: colors.primary,
                  label: 'Terms & Privacy',
                  value: 'Read and manage',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    );
                  },
                  colors: colors,
                ),
                _divider(colors),
              ],
              _settingsRow(
                icon: Icons.sort_rounded,
                iconColor: colors.primary,
                label: 'Navigation',
                value: 'Customize tab order',
                onTap: widget.onCustomizeNavigation,
                colors: colors,
              ),
            ],
          ),

          // ── Danger group ───────────────────────────────────────
          const SizedBox(height: 20),
          _sectionLabel('ACCOUNT'),
          const SizedBox(height: 8),
          _buildGroup(
            borderColor: colors.error.withAlpha(25),
            bgColor: colors.error.withAlpha(10),
            children: [
              _settingsRow(
                icon: Icons.logout_rounded,
                iconColor: colors.error,
                label: 'Logout',
                value: 'Sign out of your account',
                onTap: _logout,
                colors: colors,
                labelColor: colors.error,
              ),
              _divider(colors),
              _settingsRow(
                icon: Icons.delete_forever_rounded,
                iconColor: colors.error,
                label: 'Delete Account',
                value: 'Permanently delete everything',
                onTap: _confirmDeleteAccount,
                colors: colors,
                labelColor: colors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COUNSELOR ROW
  // ─────────────────────────────────────────────────────────────

  Widget _counselorRow(
    ColorScheme colors,
    Brightness brightness,
    Color personaColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onCounselorAvatarTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                _activePersona.avatarAsset(brightness),
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: personaColor.withAlpha(31),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: personaColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: _showCounselorPicker,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Counselor & Theme',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          '${_activePersona.displayName} · ${_activePersona.specialtyLabel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withAlpha(92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.onSurface.withAlpha(46),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SHARED COMPONENTS
  // ─────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(
    label,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
    ),
  );

  Widget _buildGroup({
    required Color borderColor,
    required Color bgColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoChip({
    required ColorScheme colors,
    required Color personaColor,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool locked = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.withAlpha(18)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: personaColor),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!locked)
                  Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: colors.onSurface.withAlpha(56),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsRow({
    IconData? icon,
    Color? iconColor,
    Widget? leadingWidget,
    required String label,
    required String value,
    required VoidCallback? onTap,
    required ColorScheme colors,
    Color? labelColor,
  }) {
    final leading =
        leadingWidget ??
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor!.withAlpha(31),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? colors.onSurface,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withAlpha(92),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: colors.onSurface.withAlpha(46),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(ColorScheme colors, Color personaColor) {
    return StreamBuilder<List<String>>(
      stream: SocialService.getMutualFriendUids(),
      builder: (context, snapshot) {
        final uids = snapshot.data ?? [];
        if (uids.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withAlpha(15)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  color: colors.onSurface.withAlpha(60),
                ),
                const SizedBox(height: 8),
                Text(
                  'No mutual friends yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withAlpha(100),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: uids.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              return FutureBuilder<Map<String, dynamic>?>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uids[i])
                    .get()
                    .then((doc) => doc.data()),
                builder: (ctx, userSnap) {
                  final data = userSnap.data;
                  final name = data?['displayName'] ?? 'User';
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: personaColor.withAlpha(30),
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: personaColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 60,
                        child: Text(
                          name.split(' ')[0],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showSocialSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SocialSearchSheet(),
    );
  }

  Widget _divider(ColorScheme colors) => Padding(
    padding: const EdgeInsets.only(left: 60),
    child: Divider(
      height: 1,
      thickness: 1,
      color: colors.outline.withAlpha(18),
    ),
  );
}
