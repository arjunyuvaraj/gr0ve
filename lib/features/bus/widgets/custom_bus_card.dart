import 'package:flutter/material.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';

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
    final hasNoCode = route.code.isEmpty;
    final displayCode = hasNoCode ? '?' : route.code;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          if (isLoggedIn) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                starred ? Icons.star_rounded : Icons.star_outline_rounded,
                color: starred
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.3),
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
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: hasNoCode
                  ? colors.errorContainer.withOpacity(0.5)
                  : colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                displayCode,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: hasNoCode ? colors.onErrorContainer : colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
