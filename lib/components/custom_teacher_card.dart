import 'package:flutter/material.dart';

class CustomTeacherCard extends StatelessWidget {
  final String name;
  final String department;
  final String email;
  final String status;
  final bool starred;
  final GestureDragCancelCallback onTap;
  final bool star;

  const CustomTeacherCard({
    super.key,
    required this.department,
    required this.email,
    required this.name,
    required this.status,
    required this.starred,
    required this.onTap,
    required this.star,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12, width: 1.2),
      ),

      child: Stack(
        children: [
          // --- Main content ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      department,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: !status.contains("Present")
                        ? Colors.redAccent
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: !status.contains("Present")
                          ? Colors.redAccent
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
          star
              ? Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onTap,
                    child: Icon(
                      starred ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 30,
                      color: starred ? Colors.amber.shade600 : Colors.black45,
                    ),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}
