import 'dart:async';
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

  void _scheduleRefresh() {
    _refreshTimer?.cancel();

    // Simple 5-minute refresh interval
    _refreshTimer = Timer(const Duration(minutes: 5), () {
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
    return Column(
      children: [
        const CustomHeader(title: "BUSES", subtitle: ""),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) {
            searchQuery = value;
            applyFilters();
          },
          decoration: const InputDecoration(
            hintText: 'Search buses or parking spots...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? const PremiumLoadingIndicator()
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
                              runSpacing: 16,
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
    );
  }
}
