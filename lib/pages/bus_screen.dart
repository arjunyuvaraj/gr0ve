import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_bus_card.dart';
import 'package:gr0ve/components/custom_header.dart';
import 'package:gr0ve/services/bus_service.dart';
import 'package:gr0ve/services/starred_bus_service.dart';

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
  Set<String> starredTowns = {};

  @override
  void initState() {
    super.initState();
    loadStarredTowns();
    loadRoutes();
  }

  Future<void> loadStarredTowns() async {
    final towns = await StarredBusService.getStarredTowns();
    if (!mounted) return;

    setState(() => starredTowns = towns);
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
        filterRoutes(searchQuery);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
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

  void filterRoutes(String query) {
    searchQuery = query.toLowerCase();

    final results = allRoutes.where((route) {
      final townMatch = route.town.toLowerCase().contains(searchQuery);
      final codeMatch = route.code.toLowerCase().contains(searchQuery);
      return townMatch || codeMatch;
    }).toList();

    results.sort((a, b) {
      final aStar = starredTowns.contains(a.town);
      final bStar = starredTowns.contains(b.town);

      if (aStar && !bStar) return -1;
      if (!aStar && bStar) return 1;

      return a.town.compareTo(b.town);
    });

    setState(() => filteredRoutes = results);
  }

  Future<void> toggleTown(BusRoute route) async {
    await StarredBusService.toggleTown(route.town);
    final updated = await StarredBusService.getStarredTowns();
    if (!mounted) return;

    setState(() {
      starredTowns = updated;
      filterRoutes(searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CustomHeader(title: "BUSES", subtitle: "DISMISSAL PLACES"),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              isDense: true,
              hintText: "Search town or bus code…",
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: filterRoutes,
          ),

          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRoutes.isEmpty
                ? const Center(child: Text("No buses found"))
                : LayoutBuilder(
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
                            children: filteredRoutes.map((route) {
                              final isStarred = starredTowns.contains(
                                route.town,
                              );

                              return SizedBox(
                                width: cardWidth,
                                child: CustomBusCard(
                                  route: route,
                                  starred: isStarred,
                                  onStarTap: () => toggleTown(route),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
