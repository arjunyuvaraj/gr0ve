import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _CustomTeacherCardState extends State<CustomTeacherCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isAbsent = !widget.status.contains("Present");

    return AnimatedScale(
      scale: expanded ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
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
          child: InkWell(
            onTap: () => setState(() => expanded = !expanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (widget.showStar)
                        GestureDetector(
                          onTap: widget.onStarTap,
                          child: AnimatedScale(
                            scale: widget.starred ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              widget.starred
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 26,
                              color: widget.starred
                                  ? colors.primary
                                  : colors.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                      if (widget.showStar) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isAbsent
                              ? colors.errorContainer.withOpacity(0.5)
                              : colors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          widget.status,
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isAbsent
                                ? colors.onErrorContainer
                                : colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.school_rounded,
                      widget.department,
                      colors,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.email_rounded,
                      widget.email,
                      colors,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    ColorScheme colors, {
    TextOverflow overflow = TextOverflow.visible,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.onSurface.withOpacity(0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: overflow,
            style: TextStyle(
              color: colors.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
