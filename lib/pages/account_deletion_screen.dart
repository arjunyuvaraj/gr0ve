import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_header.dart';

class AccountDeletionInfoScreen extends StatelessWidget {
  const AccountDeletionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomHeader(
              title: 'ACCOUNT DELETION',
              subtitle: 'Yes, you can delete your account. Here\'s how.',
            ),

            const SizedBox(height: 24),

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

            Text(
              'If you are unable to access your account, please contact support.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: colors.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
