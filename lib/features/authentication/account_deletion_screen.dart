import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';

class AccountDeletionInfoScreen extends StatelessWidget {
  const AccountDeletionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final horizontalPadding = isMobile ? 16.0 : 48.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomHeader(
                    title: 'ACCOUNT DELETION',
                    subtitle: 'Yes, you can delete your account. Here\'s how.',
                  ),
                  const SizedBox(height: 32),

                  _InfoCard(
                    title: 'How to delete your gr0ve account',
                    content:
                        'Account deletion is handled directly inside the app.\n\n'
                        'Steps:\n'
                        '1. Go to the Account page\n'
                        '2. Tap the three dots on your user card\n'
                        '3. Select “Delete Account”\n'
                        '4. Enter your password to confirm\n'
                        '5. Your account is deleted immediately',
                  ),
                  const SizedBox(height: 16),

                  _InfoCard(
                    title: 'What data is deleted',
                    content:
                        'When you delete your account:\n'
                        '• Your authentication account is removed\n'
                        '• All associated user data is permanently deleted\n'
                        '• This action cannot be undone',
                  ),
                  const SizedBox(height: 16),

                  _InfoCard(
                    title: 'Data retention',
                    content:
                        'gr0ve does not retain any personal data after account deletion.',
                  ),
                  const SizedBox(height: 16),

                  _InfoCard(
                    title: 'Deletion timeline',
                    content:
                        'Account deletion is processed immediately after confirmation.',
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: Text(
                      'If you are unable to access your account, please contact gr0ve.bca@gmail.com',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const _InfoCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: colors.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
