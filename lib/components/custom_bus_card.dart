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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Star icon ---
          // GestureDetector(
          //   onTap: onStarTap,
          //   child: Icon(
          //     starred ? Icons.star_rounded : Icons.star_border_rounded,
          //     size: 28,
          //     color: starred ? Colors.amber.shade600 : Colors.black45,
          //   ),
          // ),
          // const SizedBox(width: 12),

          // --- Center column: Town + Status ---
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.towns.join(" / "),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  route.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black.withAlpha(100),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // --- Right circle ---
          CircleAvatar(child: Text(route.code)),
        ],
      ),
    );
  }
}
