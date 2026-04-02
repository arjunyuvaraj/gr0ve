import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:async';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
import 'package:gr0ve/core/widgets/buttons/custom_secondary_button.dart';
import 'package:gr0ve/core/widgets/misc/custom_text_field.dart';
import 'package:gr0ve/core/widgets/misc/not_logged_in.dart';
import 'package:gr0ve/features/account/screens/profile_picture_picker_sheet.dart';
import 'package:gr0ve/legal/terms_screen.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/core/widgets/dialogs/confirm_dialog.dart';
import 'package:gr0ve/features/counselor/screens/counselor_persona_picker.dart';
import 'package:gr0ve/features/authentication/services/authentication_service.dart';
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/features/easter_eggs/cedite_screen.dart';
import 'package:gr0ve/features/easter_eggs/ash_screen.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/services/settings/accessibility_service.dart';
import 'package:gr0ve/services/settings/theme_color_service.dart';

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
  AppThemeColor _activeAppColor = ThemeColorService.activeColor.value;
  int _versionTapCount = 0;
  Offset _jitterOffset = Offset.zero;
  late final Timer? _jitterTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ProfilePictureService.activeVariant.addListener(_onVariantChanged);
    FirebaseAnalytics.instance.logEvent(name: 'screen_account');
    CounselorPersonaService.activePersona.addListener(_onPersonaChanged);
    ThemeColorService.activeColor.addListener(_onAppColorChanged);
    _startJitterTimer();
  }

  void _startJitterTimer() {
    _jitterTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_activePersona == CounselorPersona.cedite) {
        if (Random().nextDouble() > 0.8) {
          setState(() {
            _jitterOffset = Offset(
              (Random().nextDouble() - 0.5) * 4,
              (Random().nextDouble() - 0.5) * 4,
            );
          });
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) setState(() => _jitterOffset = Offset.zero);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    CounselorPersonaService.activePersona.removeListener(_onPersonaChanged);
    ProfilePictureService.activeVariant.removeListener(_onVariantChanged);
    ThemeColorService.activeColor.removeListener(_onAppColorChanged);
    _jitterTimer?.cancel();
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
      });
    }
  }

  void _onAppColorChanged() {
    if (mounted) {
      setState(() {
        _activeAppColor = ThemeColorService.activeColor.value;
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

  Future<void> _showAppColorPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'App Theme Color',
              style: Theme.of(
                ctx,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your favorite accent color for the app.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: AppThemeColor.values.length,
              itemBuilder: (context, index) {
                final color = AppThemeColor.values[index];
                final isSelected = color == _activeAppColor;
                final brightness = Theme.of(ctx).brightness;
                return GestureDetector(
                  onTap: () {
                    if (color == AppThemeColor.custom) {
                      _showCustomColorPicker();
                    } else {
                      ThemeColorService.setColor(color);
                      Navigator.pop(ctx);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.color(brightness).withOpacity(0.12)
                          : Theme.of(
                              ctx,
                            ).colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color.color(brightness)
                            : Theme.of(
                                ctx,
                              ).colorScheme.outline.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color.color(brightness),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : (color == AppThemeColor.custom
                                    ? const Icon(
                                        Icons.add,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          color.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? color.color(brightness)
                                : Theme.of(ctx).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomColorPicker() async {
    Color selectedColor = ThemeColorService.customColorValue;
    String hexInput = selectedColor.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
    final controller = TextEditingController(text: hexInput);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final surfaceColor = Theme.of(ctx).colorScheme.surface;
          final contrast = _getContrastRatio(selectedColor, surfaceColor);
          final isAccessible =
              contrast >= 3.0; // 3:1 is minimum for large text/ui elements

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Custom Theme Color',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a hex code to create your own style.',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              ctx,
                            ).colorScheme.outline.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isAccessible
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: contrast > 4.5
                              ? Colors.white
                              : (selectedColor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              hintText: 'HEX (e.g. FF5733)',
                              controller: controller,
                              obscureText: false,
                              onChange: (val) {
                                try {
                                  String cleanHex = val
                                      .replaceAll('#', '')
                                      .trim();
                                  if (cleanHex.length == 6) {
                                    final newColor = Color(
                                      int.parse('FF$cleanHex', radix: 16),
                                    );
                                    setModalState(() {
                                      selectedColor = newColor;
                                      hexInput = cleanHex;
                                    });
                                  }
                                } catch (_) {}
                              },
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isAccessible
                                            ? Colors.green
                                            : Colors.orange)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAccessible
                                        ? Icons.verified_user_rounded
                                        : Icons.info_outline_rounded,
                                    size: 12,
                                    color: isAccessible
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAccessible
                                        ? "Good contrast (${contrast.toStringAsFixed(1)}:1)"
                                        : "Low contrast (${contrast.toStringAsFixed(1)}:1)",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isAccessible
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CustomPrimaryButton(
                      label: 'Save Custom Color',
                      onTap: () {
                        ThemeColorService.setCustomColor(selectedColor);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _getRelativeLuminance(Color color) {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;
    r = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _getContrastRatio(Color color1, Color color2) {
    final l1 = _getRelativeLuminance(color1);
    final l2 = _getRelativeLuminance(color2);
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
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

    final appColor = colors.primary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 25 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildHero(colors, brightness, isDark, appColor, theme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 32, 0),
            child: Column(
              children: [
                _buildBody(colors, brightness, isDark, appColor),
                const SizedBox(height: 48),
                _buildVersionInfo(colors),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(ColorScheme colors) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() => _versionTapCount++);
          if (_versionTapCount == 7 && _activePersona == CounselorPersona.ash) {
            _showAshWarning();
          }
          if (_versionTapCount == 10 && !CounselorPersonaService.ashUnlocked) {
            _showAshUnlockPuzzle();
          }
        },
        child: Text(
          'v1.2.0 (Stable)\nBuilt with ❤️ by gr0ve',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: colors.onSurface.withAlpha(50),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showAshWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFC43D3D), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFC43D3D)),
            SizedBox(width: 12),
            Text('A Silent Warning', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'I have seen the end of this path. The growth you seek is hollow if built on shifting sands. '
          'Remember: when the fire fades, only what was truly earned remains.',
          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'I understand.',
              style: TextStyle(color: Color(0xFFC43D3D)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAshUnlockPuzzle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AshRuinScreen(
          onUnlocked: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Persona Unlocked: Ash (The Ruin)'),
                backgroundColor: Color(0xFFC43D3D),
              ),
            );
          },
        ),
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
                  colors.primary.withAlpha(isDark ? 140 : 97),
                  colors.primary.withAlpha(isDark ? 25 : 13),
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
                      border: Border.all(color: colors.primary, width: 3),
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
                          color: colors.primary.withAlpha(38),
                          child: Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: colors.primary,
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
                        color: colors.primary,
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
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
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
            ),
            const SizedBox(height: 20),
          ],

          // ── Student info chips ─────────────────────────────────
          if (isBergenStudent) ...[
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('STUDENT INFO'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoChip(
                        colors: colors,
                        personaColor: colors.primary,
                        icon: Icons.school_rounded,
                        label: userGrade != null
                            ? 'Grade $userGrade'
                            : 'Set grade',
                        onTap: isEmailVerified ? _updateGrade : null,
                        locked: !isEmailVerified,
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        colors: colors,
                        personaColor: colors.primary,
                        icon: Icons.apartment_rounded,
                        label: userAcademy ?? 'Set academy',
                        onTap: isEmailVerified ? _updateAcademy : null,
                        locked: !isEmailVerified,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Chatbot & appearance group ─────────────────────────
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                      label: 'Profile Picture',
                      value: _activeVariant.displayName,
                      onTap: _showProfilePicturePicker,
                      colors: colors,
                    ),
                    _divider(colors),
                    _settingsRow(
                      icon: Icons.palette_rounded,
                      iconColor: _activeAppColor.color(brightness),
                      label: 'App Primary Color',
                      value: _activeAppColor.displayName,
                      onTap: _showAppColorPicker,
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    _divider(colors),
                    ValueListenableBuilder<bool>(
                      valueListenable: AccessibilityService.autoVoiceGreeting,
                      builder: (context, autoGreet, child) {
                        return _settingsRow(
                          icon: Icons.record_voice_over_rounded,
                          iconColor: colors.primary,
                          label: 'Voice Encounter Greeting',
                          value:
                              'Counselor speaks first when you open Voice Mode',
                          onTap: () =>
                              AccessibilityService.toggleAutoVoiceGreeting(
                                !autoGreet,
                              ),
                          colors: colors,
                          trailingWidget: Switch(
                            value: autoGreet,
                            onChanged: (val) =>
                                AccessibilityService.toggleAutoVoiceGreeting(
                                  val,
                                ),
                            activeColor: colors.primary,
                          ),
                        );
                      },
                    ),
                    _divider(colors),
                    ValueListenableBuilder<bool>(
                      valueListenable: AccessibilityService.accessibleColors,
                      builder: (context, isAccessible, child) {
                        return _settingsRow(
                          icon: Icons.contrast_rounded,
                          iconColor: colors.primary,
                          label: 'Accessible Colors',
                          value:
                              'Use high-contrast, color-safe themes across the app',
                          onTap: () =>
                              AccessibilityService.toggleAccessibleColors(
                                !isAccessible,
                              ),
                          colors: colors,
                          trailingWidget: Switch(
                            value: isAccessible,
                            onChanged: (val) =>
                                AccessibilityService.toggleAccessibleColors(
                                  val,
                                ),
                            activeColor: colors.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Danger group ───────────────────────────────────────
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
    Color appColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Transform.translate(
            offset: _activePersona == CounselorPersona.cedite
                ? _jitterOffset
                : Offset.zero,
            child: GestureDetector(
              onTap: _showCounselorPicker,
              onDoubleTap: () {
                if (!CounselorPersonaService.cediteUnlocked) {
                  _showCediteUnlockPuzzle();
                }
              },
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
                      color: colors.primary.withAlpha(31),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
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

  void _showCediteUnlockPuzzle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CediteShadowScreen(
          onUnlocked: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Persona Unlocked: Cedite (The Shadow)'),
                backgroundColor: Color(0xFF9F72D8),
              ),
            );
          },
        ),
      ),
    );
  }

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
    Widget? trailingWidget,
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
            trailingWidget ??
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

  Widget _divider(ColorScheme colors) => Padding(
    padding: const EdgeInsets.only(left: 60),
    child: Divider(
      height: 1,
      thickness: 1,
      color: colors.outline.withAlpha(18),
    ),
  );
}
