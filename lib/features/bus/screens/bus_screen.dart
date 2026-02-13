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

  @override
  void initState() {
    super.initState();
    StarredBusService.load();
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

    return Column(
      children: [
        const CustomHeader(title: "BUSES", subtitle: ""),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) {
            setState(() => searchQuery = value);
          },
          decoration: const InputDecoration(
            hintText: 'Search buses or parking spots...',
            prefixIcon: Icon(Icons.search_rounded),
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

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: orderedRoutes.map((route) {
                            final isStarred = starredTowns.contains(route.town);

                            return SizedBox(
                              width: cardWidth,
                              child: CustomBusCard(
                                route: route,
                                starred: isStarred,
                                onStarTap: () =>
                                    StarredBusService.toggleTown(route.town),
                                isLoggedIn: isLoggedIn,
                              ),
                            );
                          }).toList(),
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
    );
  }
}
