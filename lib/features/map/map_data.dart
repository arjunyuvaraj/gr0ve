// map_data.dart
// FINAL VERSION - Based on exact red corridor traces from photos
import 'dart:math' as math;

enum Level { upper, main, lower }

class RoomLocation {
  final double x;
  final double y;
  final Level level;
  const RoomLocation({required this.x, required this.y, required this.level});
}

class CorridorNode {
  final double x;
  final double y;
  final Level level;
  const CorridorNode({required this.x, required this.y, required this.level});
}

class RoomDoor {
  final String roomId;
  final String corridorNodeId;
  const RoomDoor({required this.roomId, required this.corridorNodeId});
}

class RoomVisual {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  const RoomVisual({
    required this.id,
    required this.x,
    required this.y,
    this.width = 20,
    this.height = 20,
  });
}

class MapData {
  static const Map<String, RoomLocation> roomLocations = {
    // ========== UPPER LEVEL ==========
    // Left wing
    '268': RoomLocation(x: 70, y: 245, level: Level.upper),
    '266': RoomLocation(x: 119, y: 245, level: Level.upper),
    '264': RoomLocation(x: 168, y: 245, level: Level.upper),
    '262': RoomLocation(x: 217, y: 245, level: Level.upper),
    '260': RoomLocation(x: 266, y: 245, level: Level.upper),
    '258': RoomLocation(x: 315, y: 245, level: Level.upper),
    '270': RoomLocation(x: 70, y: 343, level: Level.upper),
    '267': RoomLocation(x: 119, y: 322, level: Level.upper),
    '265': RoomLocation(x: 168, y: 322, level: Level.upper),
    '263': RoomLocation(x: 217, y: 322, level: Level.upper),
    '261': RoomLocation(x: 266, y: 322, level: Level.upper),
    '259': RoomLocation(x: 315, y: 322, level: Level.upper),

    // Left-middle section
    '254': RoomLocation(x: 392, y: 245, level: Level.upper),
    '255': RoomLocation(x: 392, y: 322, level: Level.upper),
    '251': RoomLocation(x: 455, y: 245, level: Level.upper),
    '253': RoomLocation(x: 455, y: 322, level: Level.upper),
    '247': RoomLocation(x: 511, y: 245, level: Level.upper),
    '249': RoomLocation(x: 511, y: 203, level: Level.upper),
    '245': RoomLocation(x: 567, y: 245, level: Level.upper),
    '246': RoomLocation(x: 567, y: 322, level: Level.upper),
    '244': RoomLocation(x: 623, y: 322, level: Level.upper),

    // Top vertical branch (234-227)
    '234': RoomLocation(x: 700, y: 100, level: Level.upper),
    '233': RoomLocation(x: 755, y: 115, level: Level.upper),
    '235': RoomLocation(x: 700, y: 145, level: Level.upper),
    '227': RoomLocation(x: 805, y: 145, level: Level.upper),

    // Middle cluster (236-239)
    '236': RoomLocation(x: 700, y: 220, level: Level.upper),
    '237': RoomLocation(x: 700, y: 265, level: Level.upper),
    '230': RoomLocation(x: 805, y: 240, level: Level.upper),
    '238': RoomLocation(x: 805, y: 295, level: Level.upper),
    '239': RoomLocation(x: 805, y: 350, level: Level.upper),

    // Center-right (228, 226, 223)
    '228': RoomLocation(x: 900, y: 240, level: Level.upper),
    '226': RoomLocation(x: 970, y: 295, level: Level.upper),
    '223': RoomLocation(x: 970, y: 240, level: Level.upper),

    // Top-right (225-221)
    '225': RoomLocation(x: 1000, y: 145, level: Level.upper),
    '224': RoomLocation(x: 1060, y: 105, level: Level.upper),
    '224A': RoomLocation(x: 1060, y: 165, level: Level.upper),
    '221': RoomLocation(x: 1130, y: 165, level: Level.upper),

    // Far right (222, 216, 215)
    '222': RoomLocation(x: 1200, y: 240, level: Level.upper),
    '216': RoomLocation(x: 1270, y: 80, level: Level.upper),
    '215': RoomLocation(x: 1220, y: 140, level: Level.upper),

    // Bottom-right (213-204)
    '213': RoomLocation(x: 1270, y: 295, level: Level.upper),
    '211': RoomLocation(x: 1340, y: 285, level: Level.upper),
    '206': RoomLocation(x: 1400, y: 285, level: Level.upper),
    '201': RoomLocation(x: 1470, y: 285, level: Level.upper),
    '202': RoomLocation(x: 1470, y: 322, level: Level.upper),
    '203': RoomLocation(x: 1470, y: 357, level: Level.upper),
    '212': RoomLocation(x: 1270, y: 345, level: Level.upper),
    '210': RoomLocation(x: 1320, y: 345, level: Level.upper),
    '204': RoomLocation(x: 1390, y: 345, level: Level.upper),

    // UPPER CORRIDORS - one main horizontal with vertical branch
    'H_upper_1': RoomLocation(x: 196, y: 280, level: Level.upper), // Far left
    'H_upper_2': RoomLocation(
      x: 392,
      y: 280,
      level: Level.upper,
    ), // Left-middle
    'H_upper_3': RoomLocation(
      x: 700,
      y: 280,
      level: Level.upper,
    ), // Center (main junction)
    'H_upper_3_up': RoomLocation(
      x: 700,
      y: 150,
      level: Level.upper,
    ), // Vertical branch up
    'H_upper_4': RoomLocation(x: 970, y: 260, level: Level.upper), // Right
    'H_upper_5': RoomLocation(x: 1200, y: 260, level: Level.upper), // Far right
    'H_upper_5_up': RoomLocation(
      x: 1200,
      y: 100,
      level: Level.upper,
    ), // Vertical to 216
    // ========== MAIN LEVEL ==========
    // Left section
    '180': RoomLocation(x: 77, y: 329, level: Level.main),
    '179': RoomLocation(x: 77, y: 392, level: Level.main),
    '178': RoomLocation(x: 133, y: 329, level: Level.main),
    '177': RoomLocation(x: 133, y: 392, level: Level.main),
    '176': RoomLocation(x: 189, y: 329, level: Level.main),
    '175': RoomLocation(x: 189, y: 392, level: Level.main),
    '174': RoomLocation(x: 245, y: 329, level: Level.main),
    '173': RoomLocation(x: 245, y: 392, level: Level.main),
    '169': RoomLocation(x: 301, y: 413, level: Level.main),
    '168': RoomLocation(x: 301, y: 329, level: Level.main),
    '167': RoomLocation(x: 357, y: 329, level: Level.main),
    '166': RoomLocation(x: 357, y: 413, level: Level.main),
    '165': RoomLocation(x: 413, y: 329, level: Level.main),
    '164': RoomLocation(x: 469, y: 413, level: Level.main),

    // Middle-left section
    '147': RoomLocation(x: 588, y: 154, level: Level.main),
    '146': RoomLocation(x: 651, y: 154, level: Level.main),
    '148': RoomLocation(x: 588, y: 210, level: Level.main),
    '149': RoomLocation(x: 588, y: 266, level: Level.main),
    '142': RoomLocation(x: 651, y: 266, level: Level.main),
    '140': RoomLocation(x: 742, y: 217, level: Level.main),
    '150': RoomLocation(x: 588, y: 322, level: Level.main),
    '151': RoomLocation(x: 588, y: 378, level: Level.main),
    '152': RoomLocation(x: 658, y: 378, level: Level.main),
    '154': RoomLocation(x: 588, y: 441, level: Level.main),
    '153': RoomLocation(x: 658, y: 441, level: Level.main),
    '141': RoomLocation(x: 742, y: 360, level: Level.main),

    // Center section
    '137': RoomLocation(x: 833, y: 189, level: Level.main),
    '139': RoomLocation(x: 833, y: 378, level: Level.main),
    '138': RoomLocation(x: 882, y: 378, level: Level.main),
    '134': RoomLocation(x: 980, y: 245, level: Level.main),
    '136': RoomLocation(x: 1025, y: 301, level: Level.main),

    // Upper-right section
    '111': RoomLocation(x: 1080, y: 217, level: Level.main),
    '112': RoomLocation(x: 1130, y: 252, level: Level.main),
    '110': RoomLocation(x: 1180, y: 154, level: Level.main),

    // Right section
    '116': RoomLocation(x: 1210, y: 322, level: Level.main),
    '115': RoomLocation(x: 1120, y: 413, level: Level.main),
    '117': RoomLocation(x: 1176, y: 413, level: Level.main),
    '118': RoomLocation(x: 1232, y: 413, level: Level.main),
    '120': RoomLocation(x: 1288, y: 413, level: Level.main),
    '122': RoomLocation(x: 1260, y: 322, level: Level.main),
    '125': RoomLocation(x: 1323, y: 322, level: Level.main),
    '124': RoomLocation(x: 1344, y: 413, level: Level.main),

    '104': RoomLocation(x: 1253, y: 98, level: Level.main),
    '101': RoomLocation(x: 1561, y: 210, level: Level.main),

    // MAIN CORRIDORS - complex path: left → up → right → down
    'H_main_1': RoomLocation(
      x: 245,
      y: 360,
      level: Level.main,
    ), // Left horizontal
    'H_main_2': RoomLocation(
      x: 550,
      y: 360,
      level: Level.main,
    ), // Turn up point
    'H_main_3': RoomLocation(
      x: 550,
      y: 250,
      level: Level.main,
    ), // Vertical section
    'H_main_4': RoomLocation(
      x: 1050,
      y: 250,
      level: Level.main,
    ), // Upper horizontal
    'H_main_5': RoomLocation(
      x: 1200,
      y: 250,
      level: Level.main,
    ), // Turn down point
    'H_main_6': RoomLocation(
      x: 1200,
      y: 340,
      level: Level.main,
    ), // Right section
    // ========== LOWER LEVEL ==========
    '41': RoomLocation(x: 259, y: 231, level: Level.lower),
    '40': RoomLocation(x: 336, y: 231, level: Level.lower),
    '42': RoomLocation(x: 259, y: 287, level: Level.lower),
    '43': RoomLocation(x: 259, y: 343, level: Level.lower),
    '44': RoomLocation(x: 259, y: 399, level: Level.lower),
    '45': RoomLocation(x: 259, y: 455, level: Level.lower),
    '46': RoomLocation(x: 322, y: 455, level: Level.lower),
    '48': RoomLocation(x: 259, y: 511, level: Level.lower),
    '47': RoomLocation(x: 322, y: 511, level: Level.lower),

    '35': RoomLocation(x: 399, y: 343, level: Level.lower),
    '33': RoomLocation(x: 539, y: 231, level: Level.lower),
    '34': RoomLocation(x: 539, y: 294, level: Level.lower),
    '31': RoomLocation(x: 595, y: 273, level: Level.lower),

    '21': RoomLocation(x: 770, y: 231, level: Level.lower),
    '20': RoomLocation(x: 847, y: 231, level: Level.lower),
    '27': RoomLocation(x: 798, y: 301, level: Level.lower),
    '19': RoomLocation(x: 882, y: 336, level: Level.lower),
    '15': RoomLocation(x: 1190, y: 266, level: Level.lower),

    // LOWER CORRIDORS - L-shaped path
    'H_lower_1': RoomLocation(x: 280, y: 380, level: Level.lower), // Left turn
    'H_lower_2': RoomLocation(
      x: 520,
      y: 380,
      level: Level.lower,
    ), // Horizontal section
    'H_lower_3': RoomLocation(
      x: 750,
      y: 380,
      level: Level.lower,
    ), // Turn up point
    'H_lower_4': RoomLocation(
      x: 750,
      y: 250,
      level: Level.lower,
    ), // Right section with vertical
    'H_lower_5': RoomLocation(
      x: 1100,
      y: 250,
      level: Level.lower,
    ), // Far right horizontal
  };

  // CONNECTIONS - Based EXACTLY on red corridor traces
  static const Map<String, List<String>> rawConnections = {
    // ========== UPPER LEVEL ==========
    // Left wing
    '268': ['266', 'H_upper_1'],
    '266': ['268', '264'],
    '264': ['266', '262'],
    '262': ['264', '260'],
    '260': ['262', '258'],
    '258': ['260', 'H_upper_2'],
    '270': ['H_upper_1'],
    '267': ['265', 'H_upper_1'],
    '265': ['267', '263'],
    '263': ['265', '261'],
    '261': ['263', '259'],
    '259': ['261', 'H_upper_2'],

    // Left-middle
    '254': ['H_upper_2'],
    '255': ['253', 'H_upper_2'],
    '251': ['H_upper_2'],
    '253': ['255', '246'],
    '247': ['H_upper_2'],
    '249': ['H_upper_2'],
    '245': ['H_upper_2'],
    '246': ['253', '244'],
    '244': ['246'],

    // Vertical branch up (234-227)
    '234': ['233', '235', 'H_upper_3_up'],
    '233': ['234', '227'],
    '235': ['234', '236'],
    '227': ['233'],

    // Middle cluster
    '236': ['235', '237', 'H_upper_3'],
    '237': ['236', 'H_upper_3'],
    '230': ['228', '238', 'H_upper_3'],
    '238': ['230', '239'],
    '239': ['238'],

    // Center-right
    '228': ['230', 'H_upper_4'],
    '226': ['223', 'H_upper_4'],
    '223': ['226', '222', 'H_upper_4'],

    // Top-right
    '225': ['224', '224A'],
    '224': ['225'],
    '224A': ['225', '221'],
    '221': ['224A', 'H_upper_4'],

    // Far right
    '222': ['223', '213', 'H_upper_5'],
    '216': ['215', 'H_upper_5_up'],
    '215': ['216', 'H_upper_5'],

    // Bottom-right
    '213': ['222', '212', '211'],
    '211': ['213', '206'],
    '206': ['211', '201'],
    '201': ['206', '202'],
    '202': ['201', '203'],
    '203': ['202', '204'],
    '212': ['213', '210'],
    '210': ['212', '204'],
    '204': ['210', '203'],

    // Upper corridor connections
    'H_upper_1': ['H_upper_2'],
    'H_upper_2': ['H_upper_1', 'H_upper_3'],
    'H_upper_3': ['H_upper_2', 'H_upper_3_up', 'H_upper_4'],
    'H_upper_3_up': ['H_upper_3'],
    'H_upper_4': ['H_upper_3', 'H_upper_5'],
    'H_upper_5': ['H_upper_4', 'H_upper_5_up'],
    'H_upper_5_up': ['H_upper_5'],

    // ========== MAIN LEVEL ==========
    // Left section
    '180': ['179', '178', 'H_main_1'],
    '179': ['180', '177'],
    '178': ['180', '176'],
    '177': ['179', '175'],
    '176': ['178', '174'],
    '175': ['177', '173'],
    '174': ['176', '168'],
    '173': ['175', '169'],
    '169': ['173', '166'],
    '168': ['174', '167'],
    '167': ['168', '165'],
    '166': ['169', 'H_main_1'],
    '165': ['167', '164'],
    '164': ['165', 'H_main_2'],

    // Middle-left
    '147': ['146', '148'],
    '146': ['147', '140'],
    '148': ['147', '149'],
    '149': ['148', '142', '150'],
    '142': ['149', '140'],
    '140': ['142', '146', '137'],
    '150': ['149', '151', 'H_main_3'],
    '151': ['150', '152'],
    '152': ['151', '153', 'H_main_3'],
    '154': ['151', '153'],
    '153': ['152', '154'],
    '141': ['H_main_3', '137'],

    // Center
    '137': ['140', '141', '134'],
    '139': ['138', 'H_main_4'],
    '138': ['139', '136'],
    '134': ['137', '111', '136', 'H_main_4'],
    '136': ['134', '138'],

    // Upper-right
    '111': ['134', '112', 'H_main_4'],
    '112': ['111', '110', 'H_main_5'],
    '110': ['112', '104'],
    '104': ['110', '101'],
    '101': ['104'],

    // Right section
    '116': ['112', '115', '122', 'H_main_6'],
    '115': ['116', '117'],
    '117': ['115', '118'],
    '118': ['117', '120'],
    '120': ['118', '124'],
    '122': ['116', '125', 'H_main_6'],
    '125': ['122', '124'],
    '124': ['120', '125'],

    // Main corridor connections - follows red path exactly
    'H_main_1': ['H_main_2'],
    'H_main_2': ['H_main_1', 'H_main_3'],
    'H_main_3': ['H_main_2', 'H_main_4'],
    'H_main_4': ['H_main_3', 'H_main_5'],
    'H_main_5': ['H_main_4', 'H_main_6'],
    'H_main_6': ['H_main_5'],

    // ========== LOWER LEVEL ==========
    '41': ['40', '42'],
    '40': ['41', '33'],
    '42': ['41', '43'],
    '43': ['42', '44', '35'],
    '44': ['43', '45', 'H_lower_1'],
    '45': ['44', '46', '48'],
    '46': ['45', '47', 'H_lower_1'],
    '48': ['45'],
    '47': ['46'],

    '35': ['43', '34'],
    '34': ['35', '31', '33', 'H_lower_2'],
    '33': ['40', '34'],
    '31': ['34', 'H_lower_2'],

    '21': ['20', '27', 'H_lower_4'],
    '20': ['21', 'H_lower_4'],
    '27': ['21', '19', 'H_lower_3'],
    '19': ['27'],
    '15': ['H_lower_5'],

    // Lower corridor connections - follows red L-shape
    'H_lower_1': ['H_lower_2'],
    'H_lower_2': ['H_lower_1', 'H_lower_3'],
    'H_lower_3': ['H_lower_2', 'H_lower_4'],
    'H_lower_4': ['H_lower_3', 'H_lower_5'],
    'H_lower_5': ['H_lower_4'],
  };

  // AUTO-GENERATED helper structures
  static final Map<String, CorridorNode> corridorNodes = (() {
    final Map<String, CorridorNode> out = {};
    roomLocations.forEach((k, v) {
      if (k.startsWith('H_')) {
        out[k] = CorridorNode(x: v.x, y: v.y, level: v.level);
      }
    });
    return out;
  })();

  static final Map<String, List<String>> corridorConnections = (() {
    final Map<String, List<String>> graph = {};
    rawConnections.forEach((key, neighbors) {
      if (!key.startsWith('H_')) return;
      final filtered = neighbors.where((n) => n.startsWith('H_')).toList();
      graph[key] = filtered;
    });
    corridorNodes.keys.forEach((k) {
      graph.putIfAbsent(k, () => []);
    });
    return graph;
  })();

  static final Map<String, RoomDoor> roomDoors = (() {
    final Map<String, RoomDoor> doors = {};
    final corridorList = corridorNodes.entries.toList();

    roomLocations.forEach((roomId, loc) {
      if (roomId.startsWith('H_')) return;

      String? bestId;
      double bestDist = double.infinity;
      for (var c in corridorList) {
        if (c.value.level != loc.level) continue;
        final d = _distance(loc.x, loc.y, c.value.x, c.value.y);
        if (d < bestDist) {
          bestDist = d;
          bestId = c.key;
        }
      }

      if (bestId != null) {
        doors[roomId] = RoomDoor(roomId: roomId, corridorNodeId: bestId);
      } else {
        doors[roomId] = RoomDoor(roomId: roomId, corridorNodeId: '');
      }
    });

    return doors;
  })();

  static final Map<String, RoomVisual> roomVisuals = (() {
    final Map<String, RoomVisual> out = {};
    roomLocations.forEach((k, v) {
      out[k] = RoomVisual(id: k, x: v.x, y: v.y);
    });
    return out;
  })();

  static List<String>? findPath(String startRoom, String endRoom) {
    if (!roomLocations.containsKey(startRoom) ||
        !roomLocations.containsKey(endRoom)) {
      return null;
    }

    if (roomLocations[startRoom]!.level != roomLocations[endRoom]!.level) {
      return null;
    }

    final startDoor = roomDoors[startRoom];
    final endDoor = roomDoors[endRoom];
    if (startDoor == null ||
        endDoor == null ||
        startDoor.corridorNodeId.isEmpty ||
        endDoor.corridorNodeId.isEmpty) {
      return null;
    }

    final startCorr = startDoor.corridorNodeId;
    final endCorr = endDoor.corridorNodeId;

    if (startCorr == endCorr) {
      return [startRoom, startCorr, endRoom];
    }

    final queue = <List<String>>[
      [startCorr],
    ];
    final visited = <String>{startCorr};

    List<String>? corridorPath;
    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current == endCorr) {
        corridorPath = path;
        break;
      }

      final neighbors = corridorConnections[current] ?? [];
      for (final n in neighbors) {
        if (!visited.contains(n)) {
          visited.add(n);
          queue.add([...path, n]);
        }
      }
    }

    if (corridorPath == null) return null;

    final List<String> result = [];
    result.add(startRoom);
    if (corridorPath.first != startCorr) {
      result.add(startCorr);
    }
    result.addAll(corridorPath);
    if (corridorPath.last != endCorr) {
      result.add(endCorr);
    }
    result.add(endRoom);

    return _squashConsecutiveDuplicates(result);
  }

  static List<String> getAllRoomNumbers() {
    return roomLocations.keys.where((k) => !k.startsWith('H_')).toList()
      ..sort();
  }

  static List<String> getRoomsByLevel(Level level) {
    return roomLocations.entries
        .where((e) => e.value.level == level && !e.key.startsWith('H_'))
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  static List<String> getCorridorNodesByLevel(Level level) {
    return corridorNodes.entries
        .where((e) => e.value.level == level)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  static CorridorNode? getCorridorNode(String id) => corridorNodes[id];

  static String? getDoorForRoom(String roomId) =>
      roomDoors[roomId]?.corridorNodeId;

  static double _distance(double x1, double y1, double x2, double y2) {
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  }

  static List<String> _squashConsecutiveDuplicates(List<String> list) {
    if (list.isEmpty) return list;
    final out = <String>[];
    String? last;
    for (final item in list) {
      if (item != last) out.add(item);
      last = item;
    }
    return out;
  }
}
