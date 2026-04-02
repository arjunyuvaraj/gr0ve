import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/bus/widgets/custom_bus_card.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  String searchQuery = "";
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    StarredBusService.load();
    FirebaseAnalytics.instance.logEvent(name: 'screen_bus');
  }

  Future<void> _refreshBusData() async {
    setState(() => isRefreshing = true);

    try {
      // Trigger refresh from Google Sheets
      await refreshBusRoutesFromSheets();

      // Wait a moment for Firestore to update
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

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
      child: Column(
        children: [
          const CustomHeader(title: "Buses"),
          const SizedBox(height: 16),
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
            child: StreamBuilder<List<BusRoute>>(
              stream: getBusRoutesStream(),
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
                              children: List.generate(orderedRoutes.length, (index) {
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
                                  key: ValueKey('${route.town}_${route.code}_bus_anim'),
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: CustomBusCard(
                                      route: route,
                                      starred: isStarred,
                                      onStarTap: () => StarredBusService
                                          .toggleTown(route.town),
                                      isLoggedIn: isLoggedIn,
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
    );
  }
}
