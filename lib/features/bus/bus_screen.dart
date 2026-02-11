import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_bus_card.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/features/bus/bus_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  List<BusRoute> allRoutes = [];
  List<BusRoute> filteredRoutes = [];

  bool isLoading = true;
  bool isRefreshing = false;
  String searchQuery = "";
  String? errorMessage;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    StarredBusService.load();
    loadRoutes();
    _scheduleRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleRefresh() async {
    _refreshTimer?.cancel();

    final now = DateTime.now();
    Duration nextRefresh;

    // Get the actual bus arrival time (accounts for minimum days and overrides)
    try {
      final arrivalTime = await getBusArrivalTime();
      final dismissalEnd = arrivalTime.add(const Duration(hours: 1));

      // Check if we're in the dismissal window (arrival time to 1 hour after)
      if (now.isAfter(arrivalTime) && now.isBefore(dismissalEnd)) {
        // Refresh every minute during dismissal
        nextRefresh = Duration(seconds: 60 - now.second);
        print('[BUS_SCREEN] In dismissal window - refreshing every minute');
      } else {
        // Refresh every hour outside dismissal
        nextRefresh = Duration(
          minutes: 60 - now.minute,
          seconds: 60 - now.second,
        );
        print('[BUS_SCREEN] Outside dismissal window - refreshing every hour');
      }
    } catch (e) {
      print('[BUS_SCREEN] Error getting bus arrival time, using default: $e');
      // Fallback to hourly refresh if there's an error
      nextRefresh = Duration(
        minutes: 60 - now.minute,
        seconds: 60 - now.second,
      );
    }

    _refreshTimer = Timer(nextRefresh, () {
      loadRoutes(silent: true);
      _scheduleRefresh(); // Schedule the next refresh
    });
  }

  Future<void> loadRoutes({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      isRefreshing = true;
    }

    try {
      final routes = await fetchBusRoutes();
      if (!mounted) return;

      setState(() {
        allRoutes = routes;
        applyFilters();
        isLoading = false;
        errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Failed to update bus data";
      });
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  void applyFilters() {
    final query = searchQuery.toLowerCase();

    final results = allRoutes.where((route) {
      return route.town.toLowerCase().contains(query) ||
          route.code.toLowerCase().contains(query);
    }).toList();

    setState(() => filteredRoutes = results);
  }

  List<BusRoute> getOrderedRoutes(Set<String> starredTowns) {
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          const CustomHeader(title: "BUSES", subtitle: "DISMISSAL PLACES"),
          const SizedBox(height: 12),
          Material(
            elevation: 4,
            shadowColor: context.colors.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search buses or parking spot...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
                applyFilters();
              },
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<Set<String>>(
                    valueListenable: StarredBusService.starredTowns,
                    builder: (context, starredTowns, _) {
                      final orderedRoutes = getOrderedRoutes(starredTowns);

                      if (orderedRoutes.isEmpty) {
                        return const Center(child: Text("No buses found"));
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
                            onRefresh: () => loadRoutes(silent: true),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: orderedRoutes.map((route) {
                                  final isStarred = starredTowns.contains(
                                    route.town,
                                  );

                                  return SizedBox(
                                    width: cardWidth,
                                    child: CustomBusCard(
                                      route: route,
                                      starred: isStarred,
                                      onStarTap: () =>
                                          StarredBusService.toggleTown(
                                            route.town,
                                          ),
                                      isLoggedIn: isLoggedIn,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
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
