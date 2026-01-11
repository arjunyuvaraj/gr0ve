import 'package:flutter/material.dart';

class CustomTeacherCard extends StatefulWidget {
  final String name;
  final String department;
  final String email;
  final String status;
  final bool starred;
  final GestureTapCallback onStarTap;
  final bool showStar;

  const CustomTeacherCard({
    super.key,
    required this.name,
    required this.department,
    required this.email,
    required this.status,
    required this.starred,
    required this.onStarTap,
    required this.showStar,
  });

  @override
  State<CustomTeacherCard> createState() => _CustomTeacherCardState();
}

class _CustomTeacherCardState extends State<CustomTeacherCard>
    with SingleTickerProviderStateMixin {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAbsent = !widget.status.contains("Present");

    return GestureDetector(
      onTap: () => setState(() => expanded = !expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showStar)
                GestureDetector(
                  onTap: widget.onStarTap,
                  child: Icon(
                    widget.starred
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 28,
                    color: widget.starred
                        ? colors.primary
                        : colors.onSurface.withAlpha(140),
                  ),
                ),
              if (widget.showStar) const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAbsent
                                ? colors.errorContainer.withAlpha(20)
                                : colors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.status,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isAbsent
                                      ? colors.onErrorContainer
                                      : colors.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 10),
                      _infoRow(
                        context,
                        Icons.school_rounded,
                        widget.department,
                      ),
                      const SizedBox(height: 4),
                      _infoRow(
                        context,
                        Icons.email_rounded,
                        widget.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String text, {
    TextOverflow overflow = TextOverflow.visible,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.onSurface.withAlpha(140)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: overflow,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
