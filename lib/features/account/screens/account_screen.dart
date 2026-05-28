import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as dart_ui;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
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
import 'package:gr0ve/services/settings/fun_mode_service.dart';
import 'package:gr0ve/services/settings/theme_color_service.dart';
import 'package:gr0ve/features/account/screens/credits_screen.dart';

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
  bool _isFunMode = FunModeService.isFunMode.value;
  int _versionTapCount = 0;
  Offset _jitterOffset = Offset.zero;
  late final Timer? _jitterTimer;

  String _appVersion = '';
  String _buildNumber = '';
  String _fcmToken = '';
  String _appIconName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ProfilePictureService.activeVariant.addListener(_onVariantChanged);
    FirebaseAnalytics.instance.logEvent(name: 'screen_account');
    CounselorPersonaService.activePersona.addListener(_onPersonaChanged);
    ThemeColorService.activeColor.addListener(_onAppColorChanged);
    FunModeService.isFunMode.addListener(_onFunModeChanged);
    _startJitterTimer();
    _loadDevInfo();
  }

  void _onFunModeChanged() {
    if (mounted) {
      setState(() {
        _isFunMode = FunModeService.isFunMode.value;
      });
    }
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
    FunModeService.isFunMode.removeListener(_onFunModeChanged);
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
        final data = await UserDocCache.get();
        if (data != null) {
          userGrade = data['grade'];
          userAcademy = data['academy'];
        }
      } catch (e) {
        debugPrint('Error loading user profile: $e');
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadDevInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final token = await FirebaseMessaging.instance.getToken() ?? 'N/A';
      final currentPersona = CounselorPersonaService.activePersona.value;
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
          _fcmToken = token;
          _appIconName = currentPersona.iosIconName;
        });
      }
    } catch (e) {
      debugPrint('[ACCOUNT] Error loading dev info: $e');
    }
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
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        final brightness = Theme.of(ctx).brightness;
        final isDark = brightness == Brightness.dark;

        final regularColors = AppThemeColor.values.where((c) {
          if (c == AppThemeColor.counselorSync) return false;
          if (c == AppThemeColor.abies)
            return CounselorPersonaService.abiesUnlocked;
          if (c == AppThemeColor.cedite)
            return CounselorPersonaService.cediteUnlocked;
          if (c == AppThemeColor.ash)
            return CounselorPersonaService.ashUnlocked;
          return true;
        }).toList();

        return BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF101010).withOpacity(0.7)
                    : Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(
                    color: colors.outline.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.onSurface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Theme',
                          style: Theme.of(ctx).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Select an accent color or sync with your counselor's persona.",
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        ThemeColorService.setColor(AppThemeColor.counselorSync);
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient:
                              _activeAppColor == AppThemeColor.counselorSync
                              ? LinearGradient(
                                  colors: [
                                    colors.primary.withAlpha(isDark ? 50 : 35),
                                    colors.primary.withAlpha(isDark ? 90 : 60),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    colors.surfaceVariant.withAlpha(150),
                                    colors.surfaceVariant.withAlpha(80),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                _activeAppColor == AppThemeColor.counselorSync
                                ? colors.primary.withAlpha(150)
                                : colors.outline.withAlpha(30),
                            width:
                                _activeAppColor == AppThemeColor.counselorSync
                                ? 1.5
                                : 1,
                          ),
                          boxShadow:
                              _activeAppColor == AppThemeColor.counselorSync
                              ? [
                                  BoxShadow(
                                    color: colors.primary.withAlpha(50),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    _activeAppColor ==
                                        AppThemeColor.counselorSync
                                    ? colors.primary
                                    : colors.surface,
                                shape: BoxShape.circle,
                                boxShadow:
                                    _activeAppColor ==
                                        AppThemeColor.counselorSync
                                    ? [
                                        BoxShadow(
                                          color: colors.primary.withAlpha(100),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.sync_rounded,
                                size: 22,
                                color:
                                    _activeAppColor ==
                                        AppThemeColor.counselorSync
                                    ? Colors.white
                                    : colors.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sync with Counselor',
                                    style: Theme.of(ctx).textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color:
                                              _activeAppColor ==
                                                  AppThemeColor.counselorSync
                                              ? colors.primary
                                              : colors.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Dynamic, persona-driven colors',
                                    style: Theme.of(ctx).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.onSurface.withOpacity(
                                            0.5,
                                          ),
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (_activeAppColor == AppThemeColor.counselorSync)
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors.primary,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      'STATIC COLORS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: colors.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: regularColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (ctx, i) {
                        final color = regularColors[i];
                        final isSelected = color == _activeAppColor;
                        final colorValue = color.color(brightness);

                        return GestureDetector(
                          onTap: () {
                            ThemeColorService.setColor(color);
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            width: 86,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorValue.withOpacity(0.12)
                                  : colors.surfaceContainerHighest.withOpacity(
                                      0.3,
                                    ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? colorValue
                                    : colors.outline.withOpacity(0.1),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorValue.withOpacity(0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colorValue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorValue.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  color.displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: isSelected
                                        ? colorValue
                                        : colors.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      'AVPA-V',
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
          content: Text('Password reset is not available for this account'),
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
          if (!_isFunMode) return;
          setState(() => _versionTapCount++);
          if (_versionTapCount == 7 && _activePersona == CounselorPersona.ash) {
            _showAshWarning();
          }
          if (_versionTapCount == 10 && !CounselorPersonaService.ashUnlocked) {
            _showAshUnlockPuzzle();
          }
        },
        child: Column(
          children: [
            Text(
              'Built by the',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurface.withAlpha(50),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Almighty Grove Keeper',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurface.withAlpha(50),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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

  Widget _buildHero(
    ColorScheme colors,
    Brightness brightness,
    bool isDark,
    Color personaColor,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final double avatarSize = isWide ? 100.0 : 86.0;
    final double bannerHeight = isLandscape ? 120.0 : (isWide ? 180.0 : 150.0);
    final double overhang = avatarSize / 2;
    final double belowBannerHeight = overhang + 52.0;

    return SizedBox(
      height: bannerHeight + belowBannerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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

          Positioned(
            top: bannerHeight - overhang,
            left: isWide ? 32 : 16,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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

          Positioned(
            top: bannerHeight + 8,
            left: avatarSize + (isWide ? 48 : 28),
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'No name set',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
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
                      _settingsRow(
                        icon: Icons.stars_rounded,
                        iconColor: colors.primary,
                        label: 'Credits',
                        value: 'App icons and testers',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreditsScreen(),
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
                    _divider(colors),
                    ValueListenableBuilder<bool>(
                      valueListenable: FunModeService.isFunMode,
                      builder: (context, funMode, child) {
                        return _settingsRow(
                          icon: Icons.celebration_rounded,
                          iconColor: colors.primary,
                          label: 'Fun Mode',
                          value: 'Enable story elements and easter eggs',
                          onTap: () => FunModeService.toggleFunMode(!funMode),
                          colors: colors,
                          trailingWidget: Switch(
                            value: funMode,
                            onChanged: (val) =>
                                FunModeService.toggleFunMode(val),
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
                _sectionLabel('DEV INFORMATION'),
                const SizedBox(height: 8),
                _buildGroup(
                  borderColor: colors.outline.withAlpha(18),
                  bgColor: colors.surfaceVariant.withAlpha(isDark ? 89 : 115),
                  children: [
                    _devInfoRow(
                      label: 'UID',
                      value: user?.uid ?? 'N/A',
                      colors: colors,
                    ),
                    _divider(colors),
                    _devInfoRow(
                      label: 'App Version',
                      value: _appVersion.isEmpty ? 'Loading...' : _appVersion,
                      colors: colors,
                    ),
                    _divider(colors),
                    _devInfoRow(
                      label: 'Build Number',
                      value: _buildNumber.isEmpty ? 'Loading...' : _buildNumber,
                      colors: colors,
                    ),
                    _divider(colors),
                    _devInfoRow(
                      label: 'App Icon',
                      value: _appIconName.isEmpty ? 'Loading...' : _appIconName,
                      colors: colors,
                    ),
                    _divider(colors),
                    _devInfoRow(
                      label: 'FCM Token',
                      value: _fcmToken.isEmpty
                          ? 'Loading...'
                          : '${_fcmToken.substring(0, _fcmToken.length.clamp(0, 24))}...',
                      fullValue: _fcmToken,
                      colors: colors,
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
    VoidCallback? onDoubleTap,
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
      onDoubleTap: onDoubleTap,
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

  Widget _devInfoRow({
    required String label,
    required String value,
    String? fullValue,
    required ColorScheme colors,
  }) {
    final copyValue = fullValue ?? value;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: copyValue));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(31),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.code_rounded, size: 17, color: colors.primary),
            ),
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
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'JetBrains Mono',
                      color: colors.onSurface.withAlpha(92),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 14,
              color: colors.onSurface.withAlpha(46),
            ),
          ],
        ),
      ),
    );
  }
}
