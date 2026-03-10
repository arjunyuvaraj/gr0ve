import 'package:flutter/material.dart';

class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isOnline;
  final double borderWidth;
  final Color? borderColor;

  const PremiumAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.isOnline = false,
    this.borderWidth = 2,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor ?? colors.primary.withOpacity(0.2),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.asset(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallback(colors),
                  )
                : _buildFallback(colors),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallback(ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.person_rounded,
        size: size * 0.6,
        color: colors.onSurfaceVariant.withOpacity(0.5),
      ),
    );
  }
}
