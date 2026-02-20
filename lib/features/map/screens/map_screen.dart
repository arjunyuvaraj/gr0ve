import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/map/map_data.dart';
import 'package:gr0ve/features/map/screens/school_map_painter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  List<String>? _currentPath;
  String _selectedLevel = 'main';

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'screen_map');
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  // ────────────────── PATH LOGIC ──────────────────

  void _findPath() {
    final start = _startController.text.trim();
    final end = _endController.text.trim();

    if (!_validateRooms(start, end)) return;

    final level = MapData.roomLocations[start]!.level;
    final result = MapData.findPath(start, end);

    setState(() {
      _currentPath = result;
      _selectedLevel = level.name;
    });

    if (result == null) {
      _snack('No path found');
    } else {
      _snack('Route found! 🎯');
    }
  }

  bool _validateRooms(String start, String end) {
    if (start.isEmpty || end.isEmpty) {
      _snack('Please enter room numbers');
      return false;
    }

    if (!MapData.roomLocations.containsKey(start)) {
      _snack('Room $start not found');
      return false;
    }

    if (!MapData.roomLocations.containsKey(end)) {
      _snack('Room $end not found');
      return false;
    }

    final startLevel = MapData.roomLocations[start]!.level;
    final endLevel = MapData.roomLocations[end]!.level;

    if (startLevel != endLevel) {
      _snack('Rooms on different levels – use stairs!');
      return false;
    }

    return true;
  }

  void _clearPath() {
    setState(() {
      _currentPath = null;
      _startController.clear();
      _endController.clear();
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ────────────────── UI ──────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        const CustomHeader(title: 'MAP'),
        const SizedBox(height: 16),

        _buildInputs(colors),
        const SizedBox(height: 12),
        _buildLevelSelector(),

        if (_hasRoute) _buildRouteInfo(colors),

        _buildLegend(colors),
        Expanded(child: _buildMap(colors)),
      ],
    );
  }

  bool get _hasRoute => _currentPath != null && _currentPath!.length > 1;

  // ────────────────── SECTIONS ──────────────────

  Widget _buildInputs(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _roomField(
                controller: _startController,
                hint: 'Start',
                icon: Icons.trip_origin,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward,
                color: colors.onSurface.withOpacity(0.3),
                size: 20,
              ),
              const SizedBox(width: 10),
              _roomField(
                controller: _endController,
                hint: 'Destination',
                icon: Icons.location_on,
                color: const Color(0xFFE63946),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _primaryButton(
                  colors,
                  Icons.explore,
                  'Find Route',
                  _findPath,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _secondaryButton(
                  colors,
                  Icons.clear_all,
                  'Clear',
                  _clearPath,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'upper',
            label: Text('Upper', style: TextStyle(fontWeight: FontWeight.w600)),
            icon: Icon(Icons.arrow_upward, size: 16),
          ),
          ButtonSegment(
            value: 'main',
            label: Text('Main', style: TextStyle(fontWeight: FontWeight.w600)),
            icon: Icon(Icons.layers, size: 16),
          ),
          ButtonSegment(
            value: 'lower',
            label: Text('Lower', style: TextStyle(fontWeight: FontWeight.w600)),
            icon: Icon(Icons.arrow_downward, size: 16),
          ),
        ],
        selected: {_selectedLevel},
        onSelectionChanged: (s) => setState(() => _selectedLevel = s.first),
        style: ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }

  Widget _buildRouteInfo(ColorScheme colors) {
    final rooms = _currentPath!.where((id) => !id.startsWith('H_')).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2432), const Color(0xFF252B3A)]
              : [const Color(0xFFF8F9FA), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3D4758) : const Color(0xFFE0E6ED),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE63946).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.route,
                  color: Color(0xFFE63946),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Route Found',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${rooms.length} stops',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rooms.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              final isLast = entry.key == rooms.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isFirst
                      ? const Color(0xFF4CAF50).withOpacity(0.15)
                      : isLast
                      ? const Color(0xFFE63946).withOpacity(0.15)
                      : colors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFirst
                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                        : isLast
                        ? const Color(0xFFE63946).withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withOpacity(0.85),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ColorScheme colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2432) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E6ED),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legend('Classroom', Colors.white, const Color(0xFFCFD8E3)),
          _legend('Hallway', const Color(0xFFE8EBF0), const Color(0xFFE8EBF0)),
          _legend(
            'Your Path',
            const Color(0xFFE63946),
            const Color(0xFFE63946),
            line: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(ColorScheme colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE0E6ED),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(80),
              constrained: false,
              panEnabled: true,
              scaleEnabled: true,
              child: CustomPaint(
                size: const Size(1000, 450),
                painter: SchoolMapPainter(
                  level: Level.values.firstWhere(
                    (l) => l.name == _selectedLevel,
                  ),
                  path: _currentPath,
                  isDarkMode: isDark,
                ),
              ),
            ),
            // Zoom hint overlay
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_in,
                      size: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pinch to zoom',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────── SMALL WIDGETS ──────────────────

  Widget _roomField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: color, size: 18),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color.withOpacity(0.5), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(
    ColorScheme colors,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _secondaryButton(
    ColorScheme colors,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _legend(String label, Color fill, Color border, {bool line = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: line ? 20 : 14,
          height: line ? 3 : 10,
          decoration: BoxDecoration(
            color: fill,
            border: line ? null : Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(line ? 2 : 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
