import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/theme/persona_theme.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_shared.dart';

// ════════════════════════════════════════════════════════════════
// CARD: BUSES
// ════════════════════════════════════════════════════════════════

class SnapshotBusCard extends StatelessWidget {
  final bool compact;
  const SnapshotBusCard({super.key, this.compact = false});

  // ── A "?" code means the route is unknown/parking — treat as error ────────
  bool _isUnknown(BusRoute bus) =>
      bus.code.trim() == '?' || bus.code.trim().isEmpty;

  String _statusLabel(BusRoute bus) {
    if (_isUnknown(bus)) return 'Unknown';
    if (bus.status case final s?) {
      return switch (s.toLowerCase()) {
        'arrived' => 'Arrived',
        'delayed' => 'Delayed',
        'en_route' || 'enroute' => 'En Route',
        _ => 'Scheduled',
      };
    }
    return 'Arrived';
  }

  // ── Semantic colors — never primary ──────────────────────────────────────
  Color _statusColor(BusRoute bus, BuildContext context) =>
      switch (_statusLabel(bus)) {
        'Arrived' => context.colors.success, // success green
        _ => context.colors.error,
      };

  @override
  Widget build(BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;

    return StreamBuilder<List<BusRoute>>(
      stream: getBusRoutesStream(),
      builder: (_, snap) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: StarredBusService.starredTowns,
          builder: (_, starred, __) {
            if (starred.isEmpty) {
              return SnapshotTile(
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      color: c.onSurface.withOpacity(0.3),
                      size: 16,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Star buses in the Buses tab.',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snap.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(
                  starred.length.clamp(1, 3),
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _ShimmerTile(c: c),
                  ),
                ),
              );
            }

            final routes = (snap.data ?? [])
                .where((r) => starred.contains(r.town))
                .toList();

            if (routes.isEmpty) {
              return SnapshotTile(
                child: Text(
                  "Your starred buses aren't in today's list.",
                  style: TextStyle(
                    fontSize: 11,
                    color: c.onSurface.withOpacity(0.4),
                  ),
                ),
              );
            }

            return Column(
              children: routes.map((bus) {
                final label = _statusLabel(bus);
                final col = _statusColor(bus, ctx);
                final unknown = _isUnknown(bus);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: SnapshotTile(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: compact ? 10 : 13,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: c.primary, size: 12),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.town,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 13.0 : 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: c.onSurface,
                                ),
                              ),
                              Text(
                                label,
                                style: TextStyle(fontSize: 11, color: col),
                              ),
                            ],
                          ),
                        ),
                        // Route code badge — red background when unknown
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            key: ValueKey(bus.code),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: unknown
                                  ? const Color(0xFFF87171).withOpacity(0.13)
                                  : c.success.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              bus.code,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: unknown
                                    ? const Color(0xFFF87171)
                                    : c.success,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// ── Skeleton shimmer ──────────────────────────────────────────────────────────
class _ShimmerTile extends StatefulWidget {
  final ColorScheme c;
  const _ShimmerTile({required this.c});
  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
    animation: _ac,
    builder: (_, __) => SnapshotTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _b(12, 12),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_b(90, 12), const SizedBox(height: 4), _b(50, 8)],
            ),
          ),
          _b(44, 28, radius: 9),
        ],
      ),
    ),
  );

  Widget _b(double w, double h, {double radius = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: widget.c.onSurface.withOpacity(0.04 + 0.04 * _ac.value),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
