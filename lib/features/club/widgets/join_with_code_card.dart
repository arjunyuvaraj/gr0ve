import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/buttons/custom_primary_button.dart';
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
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
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Someone trusted you with a code. Don’t mess it up.",
            style: context.text.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Enter club code",
              prefixIcon: const Icon(Icons.password_rounded),
            ),
          ),

          const SizedBox(height: 16),

          CustomPrimaryButton(
            label: isLoading ? "Joining..." : "Join club",
            onTap: isLoading ? () {} : onJoinPressed,
          ),
        ],
      ),
    );
  }
}
