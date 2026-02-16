import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    FirebaseAnalytics.instance.logEvent(name: 'screen_maps');
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
