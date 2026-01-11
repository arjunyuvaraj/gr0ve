import 'package:flutter/material.dart';

extension StringCasing on String {
  String get capitalized => isEmpty ? this : toUpperCase();
  String get lowercase => isEmpty ? this : toLowerCase();
  String get titleCase => split(' ').map((word) => word.capitalized).join(' ');
}

extension ThemeContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => theme.colorScheme;

  TextTheme get text => theme.textTheme;
}
