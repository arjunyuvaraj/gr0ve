import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final List<Map<String, String>> termsAndPolicySections = [
  {
    "title": "Gr0ve Terms of Service & Privacy Policy",
    "content": "Last Updated: April 5, 2026",
  },

  {
    "title": "IMPORTANT DISCLAIMERS",
    "content":
        "This app provides information in good faith, but accuracy is NOT guaranteed. Please read the following disclaimers carefully before using Gr0ve:",
  },
  {
    "title": "Counselor Information",
    "content":
        "The Counselor feature generates responses and is NOT a substitute for professional mental health, academic, or legal advice. Automated responses may be inaccurate or incomplete. Always consult a qualified professional for important decisions. The Forgotten Trees personas (Abies, Ash) are entertainment features only and must not be relied upon for any guidance.",
  },
  {
    "title": "Absences",
    "content":
        "Teacher absence information is NOT always accurate. Real-time updates may lag. Always check official school communication before relying on this data.",
  },
  {
    "title": "Buses",
    "content":
        "Bus location and schedule information is NOT always accurate. Real-time tracking may be delayed. Always refer to official bus routes and schedules from the school.",
  },
  {
    "title": "Calendar",
    "content":
        "The calendar is NOT always up to date. Dates may change without notice. Always check the official school calendar and announcements for the most current information.",
  },
  {
    "title": "Groups & Clubs",
    "content":
        "Gr0ve is NOT responsible for content, conduct, or safety within the Groups/Clubs feature. Users are responsible for their own interactions. Report inappropriate behavior through the app or to school administration.",
  },

  {"title": "PRIVACY POLICY", "content": ""},
  {
    "title": "01. Information Collection",
    "content":
        "Gr0ve collects minimal personal information. This includes data required for optional account creation, such as email addresses and passwords. For guest users, no persistent personal data is stored. Non-sensitive usage data (like feature access and preferences) may be stored locally to improve app functionality.",
  },
  {
    "title": "02. Account Management",
    "content":
        "Users may create accounts to access additional features. Email verification is required for @bergen.org accounts. Users can delete their accounts at any time via the Account page, which immediately removes all associated data from the device and the authentication system. Guest accounts are temporary and are cleared after the session ends.",
  },
  {
    "title": "03. Access to Features",
    "content":
        "Certain features, such as teacher-specific tools, require verified @bergen.org accounts. Guest users have limited access. The app clearly indicates which features are available to which user types.",
  },
  {
    "title": "04. Use of Information",
    "content":
        "Information collected (account credentials, usage preferences) is used solely to personalize the user experience, manage access to features, and maintain basic app functionality. Data is never sold, shared with third parties, or used for advertising or marketing purposes.",
  },
  {
    "title": "05. Data Sources",
    "content":
        "All school-related information displayed in Gr0ve (teacher absences, class coverage, bus locations, quick links) is sourced from publicly accessible resources maintained by Bergen County Academies and the developer. No private or internal school records are accessed without explicit permission.",
  },
  {
    "title": "06. Data Storage & Security",
    "content":
        "Account-related data (acceptance of terms, preferences) is stored in Firebase Firestore. Authentication credentials are managed by Firebase Authentication. All data is processed and stored using Google Firebase services which comply with standard security practices. Sensitive information such as passwords are never stored in plain text by the app.",
  },
  {
    "title": "07. Children's Privacy (COPPA)",
    "content":
        "Gr0ve is intended for students of Bergen County Academies, generally aged 13 and above. This app does not target children under 13 and does not knowingly collect personal information from children under 13. If a parent or guardian believes a child under 13 has created an account, they should contact us at gr0ve.bca@gmail.com to request data deletion immediately.",
  },
  {
    "title": "08. Policy Updates",
    "content":
        "Any updates to this Privacy Policy will be displayed within the app. The 'Last Updated' date reflects the most recent revision. Users are encouraged to review the policy periodically.",
  },
  {
    "title": "09. Contact Information",
    "content":
        "Developer: Arjun Yuvaraj\nEmail: gr0ve.bca@gmail.com\nFor questions about account deletion, data access, or privacy concerns, please reach out via the email above.",
  },
  {
    "title": "10. Third-Party Links",
    "content":
        "Gr0ve may provide links to external resources (e.g., school quick links, app stores). These links are provided for convenience. Gr0ve is not responsible for the privacy practices of external websites or services.",
  },
];

class TermsOfServiceModal extends StatefulWidget {
  final bool isBlockingCounselorAccess;
  final VoidCallback? onAccepted;

  const TermsOfServiceModal({
    super.key,
    this.isBlockingCounselorAccess = false,
    this.onAccepted,
  });

  @override
  State<TermsOfServiceModal> createState() => _TermsOfServiceModalState();
}

class _TermsOfServiceModalState extends State<TermsOfServiceModal> {
  bool _hasRead = false;
  late ScrollController _scrollController;
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    setState(() {
      _scrollProgress = maxScroll > 0
          ? (currentScroll / maxScroll).clamp(0, 1)
          : 1;
    });
  }

  Future<void> _handleDecline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Terms?'),
        content: const Text(
          'Declining the Terms of Service means you cannot use Gr0ve. You will be signed out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outline.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isBlockingCounselorAccess)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Please accept to continue',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Text(
                  'Terms of Service',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Read and accept to use gr0ve',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final section = termsAndPolicySections[index];
                      final title = section['title']!;
                      final content = section['content']!;
                      final isHeader = index == 0;
                      final isSectionBreak =
                          title.startsWith('PRIVACY POLICY') ||
                          title.startsWith('IMPORTANT DISCLAIMERS');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSectionBreak && index > 0)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 24,
                                bottom: 16,
                              ),
                              child: Container(
                                height: 1,
                                color: colors.outline.withOpacity(0.15),
                              ),
                            ),
                          if (isHeader)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                title,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          if (content.isNotEmpty)
                            Text(
                              content,
                              style: textTheme.bodySmall?.copyWith(
                                height: 1.6,
                                color: colors.onSurface.withOpacity(0.8),
                              ),
                            ),
                          if (index < termsAndPolicySections.length - 1)
                            const SizedBox(height: 20),
                        ],
                      );
                    }, childCount: termsAndPolicySections.length),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 3,
            decoration: BoxDecoration(color: colors.outline.withOpacity(0.1)),
            child: FractionallySizedBox(
              widthFactor: _scrollProgress,
              alignment: Alignment.centerLeft,
              child: Container(color: colors.primary),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.outline.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _hasRead = !_hasRead),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _hasRead
                            ? colors.primary.withOpacity(0.3)
                            : colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _hasRead,
                            onChanged: (val) {
                              setState(() => _hasRead = val ?? false);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'I understand and accept the Terms of Service',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hasRead
                        ? () async {
                            await TermsOfServiceService.acceptTerms();
                            if (mounted) Navigator.pop(context);
                            widget.onAccepted?.call();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      disabledBackgroundColor: colors.primary.withOpacity(0.35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.isBlockingCounselorAccess
                          ? 'Accept & Continue'
                          : 'I Understand',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                if (widget.isBlockingCounselorAccess) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleDecline,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: colors.outline.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TermsOfServiceService {
  static const String _termsKey = 'accepted_terms_of_service';
  static bool? _localAcceptedCache;

  static Future<bool> hasAcceptedTerms() async {
    if (_localAcceptedCache == true) return true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 3));
      final accepted = doc.data()?[_termsKey] as bool? ?? false;
      if (accepted) _localAcceptedCache = true;
      return accepted;
    } catch (_) {
      try {
        final cacheDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));
        final accepted = cacheDoc.data()?[_termsKey] as bool? ?? false;
        if (accepted) _localAcceptedCache = true;
        return accepted;
      } catch (e) {
        return false;
      }
    }
  }

  static Future<void> acceptTerms() async {
    _localAcceptedCache = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            _termsKey: true,
            'terms_accepted_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint(
                '[TermsOfService] Network slow, queued write locally.',
              );
            },
          );
      debugPrint('[TermsOfService] Terms accepted and saved');
    } catch (e) {
      debugPrint('[TermsOfService] Error saving acceptance: $e');
    }
  }

  static Future<void> showIfNeeded(
    BuildContext context, {
    bool isBlockingCounselorAccess = true,
  }) async {
    final hasAccepted = await hasAcceptedTerms();
    if (hasAccepted) return;

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => TermsOfServiceModal(
          isBlockingCounselorAccess: isBlockingCounselorAccess,
        ),
      );
    }
  }

  static void showForce(BuildContext context, {VoidCallback? onAccepted}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TermsOfServiceModal(
        isBlockingCounselorAccess: false,
        onAccepted: onAccepted,
      ),
    );
  }

  static Future<void> reset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {_termsKey: false},
      );
    } catch (_) {}
  }
}
