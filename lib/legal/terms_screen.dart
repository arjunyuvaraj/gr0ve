import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/legal/legal.dart';

class TermsOfServiceScreen extends StatefulWidget {
  final bool isBlocking;
  const TermsOfServiceScreen({super.key, this.isBlocking = false});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  late ScrollController _scrollController;
  double _scrollProgress = 0;
  bool _hasRead = false;

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
      // Mark as read when user scrolls most of the way
      if (_scrollProgress > 0.85) {
        _hasRead = true;
      }
    });
  }

  Future<void> _acceptTerms() async {
    await TermsOfServiceService.acceptTerms();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _declineTerms() async {
    if (!widget.isBlocking) {
      Navigator.pop(context);
      return;
    }
    // Show confirmation before signing out
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Terms?'),
        content: const Text(
          'Declining the Terms of Service means you cannot use Gr0ve. You will be signed out.'
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Terms of Service',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        leading: !widget.isBlocking
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          // Scroll progress indicator
          Container(
            height: 2,
            color: colors.outline.withOpacity(0.1),
            child: FractionallySizedBox(
              widthFactor: _scrollProgress,
              alignment: Alignment.centerLeft,
              child: Container(color: colors.primary),
            ),
          ),
          // Content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final section = termsAndPolicySections[index];
                      final title = section['title']!;
                      final content = section['content']!;
                      final isHeader = index == 0;
                      final isSectionBreak =
                          title.startsWith('PRIVACY POLICY') ||
                          title.startsWith('⚠️ IMPORTANT DISCLAIMERS');

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
          // Bottom action buttons
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.outline.withOpacity(0.1)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox for acceptance
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
                  // Action buttons
                  Row(
                    children: [
                      // Decline button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _declineTerms(),
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
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _hasRead ? _acceptTerms : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            disabledBackgroundColor: colors.primary.withOpacity(
                              0.35,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Accept',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
