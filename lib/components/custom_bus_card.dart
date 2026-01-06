import 'package:flutter/material.dart';
import 'package:gr0ve/services/bus_service.dart';

class CustomBusCard extends StatelessWidget {
  final BusRoute route;
  final bool starred;
  final GestureTapCallback onStarTap;

  const CustomBusCard({
    super.key,
    required this.route,
    required this.starred,
    required this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withAlpha(12), // slightly softer shadow
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Towns
                Text(
                  route.towns.join(" / "),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6), // subtle spacing like teacher card
                // Status
                Text(
                  route.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withAlpha(120), // softer alpha
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Route Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: route.code == "?"
                  ? colors.error.withAlpha(24)
                  : colors.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(
                18,
              ), // matches teacher card style
            ),
            child: Text(
              route.code,
              style: theme.textTheme.labelLarge?.copyWith(
                color: route.code == "?" ? colors.error : colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
