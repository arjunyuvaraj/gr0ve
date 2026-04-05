import 'package:flutter/material.dart';

class ChangelogFeature {
  final dynamic icon;
  final String title;
  final String description;
  final Color? color;

  const ChangelogFeature({
    required this.icon,
    required this.title,
    required this.description,
    this.color,
  });
}

class ChangelogVersion {
  final String version;
  final String tagline;
  final String description;
  final List<ChangelogFeature> features;

  const ChangelogVersion({
    required this.version,
    required this.tagline,
    required this.description,
    required this.features,
  });
}
