import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gr0ve/features/map/map_data.dart';

class SchoolMapPainter extends CustomPainter {
  final Level level;
  final List<String>? path;
  final bool isDarkMode;

  SchoolMapPainter({
    required this.level,
    required this.path,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visuals = MapData.roomVisuals.entries
        .where((e) => MapData.roomLocations[e.key]?.level == level)
        .toList();

    if (visuals.isEmpty) return;

    // ---------- bounds ----------
    final minX = visuals.map((e) => e.value.x).reduce(math.min);
    final maxX = visuals.map((e) => e.value.x).reduce(math.max);
    final minY = visuals.map((e) => e.value.y).reduce(math.min);
    final maxY = visuals.map((e) => e.value.y).reduce(math.max);

    const padding = 60.0;
    final scale = math.min(
      (size.width - padding * 2) / (maxX - minX),
      (size.height - padding * 2) / (maxY - minY),
    );

    Offset tx(double x, double y) =>
        Offset((x - minX) * scale + padding, (y - minY) * scale + padding);

    // ---------- modern gr0ve paints ----------
    final hallwayPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF383E4A) : const Color(0xFFE8EBF0)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square;

    final roomFill = Paint()
      ..color = isDarkMode ? const Color(0xFF1E2432) : Colors.white;

    final roomBorder = Paint()
      ..color = isDarkMode ? const Color(0xFF3D4758) : const Color(0xFFCFD8E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pathPaint = Paint()
      ..color = isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFE63946)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pathGlowPaint = Paint()
      ..color = (isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFE63946))
          .withOpacity(0.2)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    // ---------- hallways (L-shaped only) ----------
    final corridorIds = MapData.getCorridorNodesByLevel(level);
    for (final id in corridorIds) {
      final node = MapData.getCorridorNode(id)!;
      final a = tx(node.x, node.y);

      for (final n in MapData.corridorConnections[id] ?? []) {
        if (!corridorIds.contains(n)) continue;
        final bNode = MapData.getCorridorNode(n)!;
        final b = tx(bNode.x, bNode.y);
        _drawLShapedLine(canvas, a, b, hallwayPaint);
      }
    }

    // ---------- room → corridor (L-shaped connections) ----------
    MapData.roomDoors.forEach((roomId, door) {
      final loc = MapData.roomLocations[roomId];
      if (loc == null || loc.level != level) return;

      final room = MapData.roomVisuals[roomId]!;
      final corridor = MapData.getCorridorNode(door.corridorNodeId);
      if (corridor == null) return;

      _drawLShapedLine(
        canvas,
        tx(room.x, room.y),
        tx(corridor.x, corridor.y),
        hallwayPaint,
      );
    });

    // ---------- rooms (properly sized with good padding) ----------
    for (final e in visuals) {
      if (e.key.startsWith('H_')) continue;

      final r = e.value;
      final center = tx(r.x, r.y);

      // Larger room size for better text padding
      final roomSize = (24 * scale).clamp(32.0, 60.0);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: roomSize, height: roomSize),
        Radius.circular(7),
      );

      // Subtle shadow
      canvas.drawRRect(
        rect.shift(const Offset(0, 1)),
        Paint()
          ..color = Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawRRect(rect, roomFill);
      canvas.drawRRect(rect, roomBorder);

      // room label with better typography and comfortable size
      final label = e.key.replaceAll('R_', '');
      final fontSize = (9 + scale * 0.7).clamp(9.0, 13.0);

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? const Color(0xFFE8EBF0) : const Color(0xFF2C3E50),
          letterSpacing: 0.3,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // ---------- path with glow effect ----------
    if (path != null && path!.length > 1) {
      // Draw glow first
      for (int i = 0; i < path!.length - 1; i++) {
        final a = MapData.roomLocations[path![i]];
        final b = MapData.roomLocations[path![i + 1]];
        if (a == null || b == null) continue;
        _drawPath(canvas, tx(a.x, a.y), tx(b.x, b.y), pathGlowPaint);
      }
      // Draw solid path on top
      for (int i = 0; i < path!.length - 1; i++) {
        final a = MapData.roomLocations[path![i]];
        final b = MapData.roomLocations[path![i + 1]];
        if (a == null || b == null) continue;
        _drawPath(canvas, tx(a.x, a.y), tx(b.x, b.y), pathPaint);
      }
    }
  }

  void _drawLShapedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    // Always draw L-shaped: horizontal then vertical
    final mid = Offset(a.dx, b.dy);
    canvas.drawLine(a, mid, paint);
    canvas.drawLine(mid, b, paint);
  }

  void _drawPath(Canvas canvas, Offset a, Offset b, Paint paint) {
    // L-shaped path for navigation
    final mid = Offset(a.dx, b.dy);
    canvas.drawLine(a, mid, paint);
    canvas.drawLine(mid, b, paint);
  }

  @override
  bool shouldRepaint(covariant SchoolMapPainter old) =>
      old.level != level || old.path != path || old.isDarkMode != isDarkMode;
}
