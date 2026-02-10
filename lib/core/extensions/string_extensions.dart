extension StringCasing on String {
  String get capitalized => isEmpty ? this : toUpperCase();
  String get lowercase => isEmpty ? this : toLowerCase();
  String get titleCase => split(' ').map((word) => word.capitalized).join(' ');
}
