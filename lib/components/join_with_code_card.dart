import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class JoinWithCodeCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onJoinPressed;
  final bool isLoading;

  const JoinWithCodeCard({
    super.key,
    required this.controller,
    required this.onJoinPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withAlpha(16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Join with code",
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Someone trusted you with a code. Don’t mess it up.",
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurface.withAlpha(140),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Enter club code",
              filled: true,
              fillColor: colors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          CustomPrimaryButton(
            label: isLoading ? "Joining..." : "Join club",
            onTap: isLoading ? () {} : onJoinPressed,
          ),
        ],
      ),
    );
  }
}
