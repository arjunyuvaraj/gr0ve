import 'package:flutter/material.dart';
import 'package:gr0ve/services/bus_service.dart';

class CustomBusCard extends StatelessWidget {
  final BusRoute route;
  final bool starred;
  final GestureTapCallback onStarTap;
  final bool isLoggedIn;

  const CustomBusCard({
    super.key,
    required this.route,
    required this.starred,
    required this.onStarTap,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isLoggedIn) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                starred ? Icons.star_rounded : Icons.star_border_rounded,
                color: starred
                    ? colors.primary
                    : colors.onSurface.withAlpha(120),
              ),
              onPressed: onStarTap,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.town,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  route.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: route.code == "?"
                  ? colors.error.withAlpha(24)
                  : colors.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              route.code,
              style: theme.textTheme.labelLarge?.copyWith(
                color: route.code == "?" ? colors.error : colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
