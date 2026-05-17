import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

class BergenOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const BergenOnboardingScreen({super.key, required this.onComplete});

  @override
  State<BergenOnboardingScreen> createState() => _BergenOnboardingScreenState();
}

class _BergenOnboardingScreenState extends State<BergenOnboardingScreen> {
  final user = FirebaseAuth.instance.currentUser;

  bool isEmailVerified = false;
  String? selectedGrade;
  String? selectedAcademy;
  bool isLoading = false;
  bool isSaving = false;
  Timer? _verificationTimer;

  final grades = ['9', '10', '11', '12'];
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

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _startVerificationTimer();
    FirebaseAnalytics.instance.logEvent(name: 'screen_onboarding');
  }

  void _startVerificationTimer() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    try {
      // Force refresh the current user's auth state from Firebase
      await FirebaseAuth.instance.currentUser?.reload();
      
      if (!mounted) return;
      
      // Get the latest user instance after reload
      final currentUser = FirebaseAuth.instance.currentUser;
      final verified = currentUser?.emailVerified ?? false;
      
      if (verified && !isEmailVerified) {
        // Email just got verified - cancel the polling timer
        _verificationTimer?.cancel();
      }
      
      setState(() {
        isEmailVerified = verified;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking email: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (user == null || user!.emailVerified) return;

    setState(() => isLoading = true);
    try {
      await user!.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
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
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (selectedGrade == null || selectedAcademy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both grade and academy'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'grade': selectedGrade, 'academy': selectedAcademy})
          .timeout(const Duration(seconds: 5));

      // Update local cache so NavigationScreen doesn't re-trigger onboarding
      UserDocCache.invalidate();
      await UserDocCache.get();

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is TimeoutException) {
        errorMessage =
            "Connection timed out. Please try again or check your internet.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 56,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Complete Your Profile',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'As a Bergen student, please verify your email and set your grade and academy',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Step 1: Email Verification
                _buildStepCard(
                  colors,
                  textTheme,
                  stepNumber: 1,
                  title: 'Verify Your Email',
                  subtitle: user?.email ?? '',
                  isComplete: isEmailVerified,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (!isEmailVerified) ...[
                        InkWell(
                          onTap: isLoading ? null : _sendVerificationEmail,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.primary,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  'Send Verification Email',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _checkEmailVerification,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'I\'ve Verified My Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Email Verified',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Step 2: Grade Selection
                _buildStepCard(
                  colors,
                  textTheme,
                  stepNumber: 2,
                  title: 'Select Your Grade',
                  subtitle: selectedGrade != null
                      ? 'Grade $selectedGrade'
                      : 'Choose your current grade',
                  isComplete: selectedGrade != null,
                  isEnabled: isEmailVerified,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: grades.map((grade) {
                          final isSelected = selectedGrade == grade;
                          return InkWell(
                            onTap: isEmailVerified
                                ? () => setState(() => selectedGrade = grade)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 70,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary.withOpacity(0.15)
                                    : colors.surface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.outline.withOpacity(0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                grade,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? colors.primary
                                      : colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Step 3: Academy Selection
                _buildStepCard(
                  colors,
                  textTheme,
                  stepNumber: 3,
                  title: 'Select Your Academy',
                  subtitle: selectedAcademy ?? 'Choose your academy',
                  isComplete: selectedAcademy != null,
                  isEnabled: isEmailVerified,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ...academies.map((academy) {
                        final isSelected = selectedAcademy == academy;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: isEmailVerified
                                ? () =>
                                      setState(() => selectedAcademy = academy)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary.withOpacity(0.15)
                                    : colors.surface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.outline.withOpacity(0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurface.withOpacity(0.3),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    academy,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? colors.primary
                                          : colors.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Complete Button
                InkWell(
                  onTap:
                      (isEmailVerified &&
                          selectedGrade != null &&
                          selectedAcademy != null &&
                          !isSaving)
                      ? _saveProfile
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color:
                          (isEmailVerified &&
                              selectedGrade != null &&
                              selectedAcademy != null)
                          ? colors.primary
                          : colors.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isSaving
                        ? Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Complete Setup',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color:
                                  (isEmailVerified &&
                                      selectedGrade != null &&
                                      selectedAcademy != null)
                                  ? Colors.white
                                  : colors.onSurface.withOpacity(0.3),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
    ColorScheme colors,
    TextTheme textTheme, {
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isComplete,
    bool isEnabled = true,
    required Widget child,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete
                ? colors.primary.withOpacity(0.3)
                : colors.outline.withOpacity(0.1),
            width: isComplete ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? colors.primary
                        : colors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isComplete
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '$stepNumber',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}
