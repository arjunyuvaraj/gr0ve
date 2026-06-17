import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/bus/widgets/custom_bus_card.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';
import 'package:gr0ve/features/admin/services/admin_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  String searchQuery = "";
  bool isRefreshing = false;
  bool isAdmin = false;
  late Future<List<BusRoute>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = fetchBusRoutes();
    StarredBusService.load();
    _checkAdmin();
    FirebaseAnalytics.instance.logEvent(name: 'screen_bus');
  }

  Future<void> _checkAdmin() async {
    final res = await AdminHelper.isCurrentUserAdmin();
    if (mounted) setState(() => isAdmin = res);
  }

  Future<void> _refreshBusData() async {
    setState(() => isRefreshing = true);

    try {
      await refreshBusRoutesFromSheets();
      _routesFuture = fetchBusRoutes();

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bus routes refreshed! \u2713'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to refresh: $e"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  List<BusRoute> applyFilters(List<BusRoute> allRoutes) {
    final query = searchQuery.toLowerCase();

    return allRoutes.where((route) {
      return route.town.toLowerCase().contains(query) ||
          route.code.toLowerCase().contains(query);
    }).toList();
  }

  List<BusRoute> getOrderedRoutes(
    List<BusRoute> filteredRoutes,
    Set<String> starredTowns,
  ) {
    return filteredRoutes.toList()..sort((a, b) {
      final aStar = starredTowns.contains(a.town);
      final bStar = starredTowns.contains(b.town);

      if (aStar && !bStar) return -1;
      if (!aStar && bStar) return 1;

      return a.town.compareTo(b.town);
    });
  }

  Future<void> _deleteBus(String town) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        final colors = Theme.of(context).colorScheme;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Delete Bus?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to remove the bus for $town?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('public_data')
          .doc('bus_routes')
          .update({'routes.$town': FieldValue.delete()});
      invalidateBusRoutesCache();
      if (mounted) {
        setState(() => _routesFuture = fetchBusRoutes());
      }
    }
  }

  Future<void> _showBusDialog({BusRoute? route}) async {
    final townCtrl = TextEditingController(text: route?.town ?? '');
    final codeCtrl = TextEditingController(text: route?.code ?? '');
    final isNew = route == null;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = Theme.of(context).colorScheme;
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isNew ? 'New Route' : 'Update Route',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: townCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Town Name',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      readOnly: !isNew,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Bus Code',
                        prefixIcon: Icon(
                          Icons.pin_outlined,
                          size: 18,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (!isNew)
                          IconButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteBus(route.town);
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 22,
                              color: colors.error.withOpacity(0.7),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Discard',
                            style: TextStyle(
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final town = townCtrl.text.trim();
                            if (town.isEmpty) return;

                            final code = codeCtrl.text.trim();
                            final status = code.isNotEmpty
                                ? 'Arrived'
                                : 'Not here yet';

                            await FirebaseFirestore.instance
                                .collection('public_data')
                                .doc('bus_routes')
                                .update({
                                  'routes.$town': {
                                    'town': town,
                                    'code': code.isEmpty ? '?' : code,
                                    'status': status,
                                  },
                                });
                            invalidateBusRoutesCache();
                            if (mounted) {
                              setState(() => _routesFuture = fetchBusRoutes());
                            }

                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
        child: Column(
          children: [
            const CustomHeader(title: "Buses"),
            if (isAdmin)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: InkWell(
                    onTap: () => _showBusDialog(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Route',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: TextField(
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
                decoration: const InputDecoration(
                  hintText: 'Search buses or parking spots...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<BusRoute>>(
                future: _routesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData) {
                    return const PremiumLoadingIndicator();
                  }

                  final allRoutes = snapshot.data!;
                  final filteredRoutes = applyFilters(allRoutes);

                  return ValueListenableBuilder<Set<String>>(
                    valueListenable: StarredBusService.starredTowns,
                    builder: (context, starredTowns, _) {
                      final orderedRoutes = getOrderedRoutes(
                        filteredRoutes,
                        starredTowns,
                      );

                      if (orderedRoutes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_rounded,
                                size: 56,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No buses found',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.4),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          int columns = 1;
                          if (constraints.maxWidth > 900) {
                            columns = 3;
                          } else if (constraints.maxWidth > 600) {
                            columns = 2;
                          }

                          final cardWidth =
                              (constraints.maxWidth - (16 * (columns - 1))) /
                              columns;

                          return RefreshIndicator(
                            onRefresh: _refreshBusData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: List.generate(orderedRoutes.length, (
                                  index,
                                ) {
                                  final route = orderedRoutes[index];
                                  final isStarred = starredTowns.contains(
                                    route.town,
                                  );

                                  return TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 15 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    key: ValueKey(
                                      '${route.town}_${route.code}_bus_anim',
                                    ),
                                    child: SizedBox(
                                      width: cardWidth,
                                      child: CustomBusCard(
                                        route: route,
                                        starred: isStarred,
                                        onStarTap: () =>
                                            StarredBusService.toggleTown(
                                              route.town,
                                            ),
                                        isLoggedIn: isLoggedIn,
                                        isAdmin: isAdmin,
                                        onEditTap: () =>
                                            _showBusDialog(route: route),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
