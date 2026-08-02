import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/widgets/images/remote_asset_image.dart';
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kTeams = ['Blue Team', 'Green Team', 'Red Team', 'Yellow Team'];

const _kTeamColors = {
  'Blue Team': Color(0xFF4396EF),
  'Green Team': Color(0xFF3DCC41),
  'Red Team': Color(0xFFD64D2F),
  'Yellow Team': Color(0xFFD4A912),
};

const _kTeamTrees = {
  'Blue Team': 'caeruleus',
  'Green Team': 'viridis',
  'Red Team': 'ruber',
  'Yellow Team': 'flavus',
};

String _teamTreeAsset(String team, Brightness brightness) {
  final tree = _kTeamTrees[team] ?? 'viridis';
  final mode = brightness == Brightness.dark ? 'dark' : 'light';
  return 'assets/field_day/${tree}_$mode.png';
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _TeamScore {
  final String name;
  final double points;
  final List<Map<String, dynamic>> events;
  const _TeamScore({
    required this.name,
    required this.points,
    this.events = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class FieldDayPage extends StatefulWidget {
  const FieldDayPage({super.key});

  @override
  State<FieldDayPage> createState() => _FieldDayPageState();
}

class _FieldDayPageState extends State<FieldDayPage>
    with SingleTickerProviderStateMixin {
  String? _myTeam;
  bool _savingTeam = false;
  late final AnimationController _pulseController;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _scoresStream;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scoresStream = _fetchScoresStream();
    _loadMyTeam();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadMyTeam() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final team = doc.data()?['fieldDayTeam'] as String?;
    if (team != null && mounted) {
      setState(() => _myTeam = team);
    }
  }

  Future<void> _saveTeam(String team) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _savingTeam = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fieldDayTeam': team,
      }, SetOptions(merge: true));
      await ProfilePictureService.refreshFieldDayTeam(
        cachedUserData: {'fieldDayTeam': team},
      );
      if (mounted) setState(() => _myTeam = team);
    } finally {
      if (mounted) setState(() => _savingTeam = false);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _fetchScoresStream() {
    return FirebaseFirestore.instance
        .collection('public_data')
        .doc('field_day_scores')
        .snapshots();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'Unknown';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is String) {
      dt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      return 'Unknown';
    }
    final hr = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day}/${dt.year} at $hr:$min $ampm';
  }

  Future<void> _refreshFieldDayFromSource() async {
    print('=' * 70);
    print('Running Field Day scrape (Dart fetch from Firestore)');
    print('=' * 70);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('public_data')
          .doc('field_day_scores')
          .get();
      if (doc.exists) {
        final data = doc.data();
        print("Scores: ${data?['scores']}");
        print("Uploaded to Firestore equivalent completed.");
      } else {
        print("Scrape returned no data");
      }
    } catch (e) {
      print("Scrape error: $e");
    }
    print('=' * 70);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  List<_TeamScore> _parseScores(Map<String, dynamic> raw) {
    final scores = (raw['scores'] as Map<String, dynamic>?) ?? {};
    final rawTables = (raw['event_tables'] as Map<String, dynamic>?) ?? {};
    final List<_TeamScore> list = [];
    for (final team in _kTeams) {
      final ptsRaw = scores[team]?['points'];
      double pts = 0.0;
      if (ptsRaw is num) {
        pts = ptsRaw.toDouble();
      } else if (ptsRaw is String) {
        pts = double.tryParse(ptsRaw) ?? 0.0;
      }
      final rawRows = rawTables[team] as List<dynamic>? ?? [];
      final events = rawRows
          .map(
            (r) => (r as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v?.toString() ?? ''),
            ),
          )
          .toList();
      list.add(_TeamScore(name: team, points: pts, events: events));
    }
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: ColoredBox(
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
          child: Column(
            children: [
              const CustomHeader(title: 'Field Day'),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _scoresStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _ErrorView(message: snap.error.toString());
                    }

                    if (!snap.hasData) {
                      return const PremiumLoadingIndicator();
                    }

                    final data = snap.data?.data();
                    final scores = data != null
                        ? _parseScores(data)
                        : <_TeamScore>[];

                    if (scores.isEmpty) {
                      return _EmptyScores(
                        onPickTeam: () => _showTeamPicker(context),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await _refreshFieldDayFromSource();
                        setState(() => _scoresStream = _fetchScoresStream());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(bottom: 28),
                        children: [
                          const SizedBox(height: 12),
                          if (data?['lastUpdated'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Last updated: ${_formatTimestamp(data!['lastUpdated'])}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          _MyTeamBanner(
                            myTeam: _myTeam,
                            saving: _savingTeam,
                            pulseController: _pulseController,
                            onTap: () => _showTeamPicker(context),
                          ),
                          ...scores.asMap().entries.map((entry) {
                            final i = entry.key;
                            final score = entry.value;
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 300 + (i % 4) * 60,
                              ),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0, end: 1),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 16 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _ScoreCard(
                                score: score,
                                rank: i + 1,
                                isMyTeam: score.name == _myTeam,
                                topScore: scores.first.points,
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTeamPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeamPickerSheet(
        currentTeam: _myTeam,
        saving: _savingTeam,
        onSelect: (team) {
          Navigator.pop(context);
          _saveTeam(team);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyScores extends StatelessWidget {
  final VoidCallback onPickTeam;

  const _EmptyScores({required this.onPickTeam});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_rounded,
              size: 56,
              color: colors.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No scores yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick your team before the board goes live.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPickTeam,
              icon: const Icon(Icons.groups_rounded, size: 18),
              label: const Text('Choose Team'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Team Banner
// ─────────────────────────────────────────────────────────────────────────────

class _MyTeamBanner extends StatelessWidget {
  final String? myTeam;
  final bool saving;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _MyTeamBanner({
    required this.myTeam,
    required this.saving,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final teamColor = myTeam != null ? _kTeamColors[myTeam!]! : colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: teamColor.withOpacity(0.22), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  myTeam != null ? Icons.groups_rounded : Icons.flag_rounded,
                  color: teamColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myTeam != null ? 'Your Team' : 'Pick Your Team',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: teamColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      myTeam ?? 'Tap to choose which team you\'re on',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (saving)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: teamColor,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurface.withOpacity(0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score Card
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Score Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final _TeamScore score;
  final int rank;
  final bool isMyTeam;
  final double topScore;

  const _ScoreCard({
    required this.score,
    required this.rank,
    required this.isMyTeam,
    required this.topScore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final teamColor = _kTeamColors[score.name] ?? colors.primary;
    final fraction = topScore > 0
        ? (score.points / topScore).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isMyTeam
              ? Color.alphaBlend(teamColor.withOpacity(0.06), colors.surface)
              : colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: isMyTeam
              ? Border.all(color: teamColor.withOpacity(0.35), width: 1.4)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _TeamDetailScreen(
                    score: score,
                    rank: rank,
                    isMyTeam: isMyTeam,
                    teamColor: teamColor,
                    topScore: topScore,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: teamColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: teamColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              score.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              score.events.isNotEmpty
                                  ? '${score.events.length} events'
                                  : 'Open to view details',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMyTeam)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: teamColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: teamColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 74),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: teamColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${score.points % 1 == 0 ? score.points.toInt() : score.points} pts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: teamColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: colors.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 6,
                        backgroundColor: teamColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(teamColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event Table
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the scraped event breakdown table for one team.
/// Columns are discovered dynamically from the row map keys.
/// Point-like columns are highlighted in the team colour.
class _EventTable extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Color teamColor;

  const _EventTable({required this.events, required this.teamColor});

  static const _kPointHeaders = {
    'pts',
    'points',
    'score',
    'place',
    'rank',
    'result',
  };

  bool _isPointCol(String header) =>
      _kPointHeaders.contains(header.toLowerCase().trim());

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: colors.onSurface.withOpacity(0.08),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 18,
                color: colors.onSurface.withOpacity(0.35),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No events posted for this team yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Discover headers from the first row
    final headers = events.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Divider(
          color: colors.onSurface.withOpacity(0.08),
          thickness: 1,
          height: 1,
        ),
        const SizedBox(height: 10),
        // Header row
        _TableRow(
          cells: headers,
          isHeader: true,
          teamColor: teamColor,
          colors: colors,
          isPointCol: _isPointCol,
        ),
        const SizedBox(height: 4),
        // Data rows
        ...events.asMap().entries.map((entry) {
          final isAlt = entry.key.isOdd;
          final row = entry.value;
          return Container(
            decoration: BoxDecoration(
              color: isAlt
                  ? colors.onSurface.withOpacity(0.03)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: _TableRow(
              cells: headers.map((h) => row[h]?.toString() ?? '—').toList(),
              isHeader: false,
              teamColor: teamColor,
              colors: colors,
              isPointCol: _isPointCol,
              headers: headers,
            ),
          );
        }),
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final Color teamColor;
  final ColorScheme colors;
  final bool Function(String) isPointCol;
  final List<String>? headers;

  const _TableRow({
    required this.cells,
    required this.isHeader,
    required this.teamColor,
    required this.colors,
    required this.isPointCol,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        children: cells.asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;
          final colHeader = headers != null ? headers![idx] : text;
          final isPtCol = isPointCol(colHeader);
          final isFirst = idx == 0;

          return Expanded(
            flex: isFirst ? 3 : 2,
            child: Text(
              text,
              textAlign: isFirst ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                fontSize: isHeader ? 10 : 13,
                fontWeight: isHeader
                    ? FontWeight.w700
                    : (isPtCol ? FontWeight.w700 : FontWeight.w500),
                color: isHeader
                    ? colors.onSurface.withOpacity(0.45)
                    : (isPtCol
                          ? teamColor
                          : colors.onSurface.withOpacity(0.85)),
                letterSpacing: isHeader ? 0.7 : 0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TeamDetailScreen extends StatelessWidget {
  final _TeamScore score;
  final int rank;
  final bool isMyTeam;
  final Color teamColor;
  final double topScore;

  const _TeamDetailScreen({
    required this.score,
    required this.rank,
    required this.isMyTeam,
    required this.teamColor,
    required this.topScore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = topScore > 0
        ? (score.points / topScore).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(score.name),
        leading: const BackButton(),
        actions: [
          if (isMyTeam)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Your team',
                    style: TextStyle(
                      color: teamColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ColoredBox(
        color: colors.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: teamColor.withOpacity(0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: teamColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: RemoteAssetImage(
                            _teamTreeAsset(
                              score.name,
                              Theme.of(context).brightness,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.park_rounded,
                              color: teamColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$rank',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: teamColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${score.points % 1 == 0 ? score.points.toInt() : score.points} points',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: teamColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(teamColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    score.events.isNotEmpty
                        ? '${score.events.length} events on the board'
                        : 'No events posted for this team yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _EventTable(events: score.events, teamColor: teamColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team Picker Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TeamPickerSheet extends StatelessWidget {
  final String? currentTeam;
  final bool saving;
  final void Function(String team) onSelect;

  const _TeamPickerSheet({
    required this.currentTeam,
    required this.saving,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Which team are you on?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'This will be saved to your GR0VE account.',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...kTeamOrder.map((team) {
            final teamColor = _kTeamColors[team]!;
            final isSelected = currentTeam == team;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: GestureDetector(
                onTap: saving ? null : () => onSelect(team),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? teamColor.withOpacity(0.14)
                        : colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: teamColor.withOpacity(0.5),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          team,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: teamColor,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

const kTeamOrder = ['Blue Team', 'Green Team', 'Red Team', 'Yellow Team'];

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t load scores',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
