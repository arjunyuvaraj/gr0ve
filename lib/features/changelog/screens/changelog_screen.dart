import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/changelog/data/changelog_models.dart';
import 'package:gr0ve/features/changelog/data/changelog_data.dart';
import 'package:gr0ve/features/changelog/screens/original_seed_screen.dart';
import 'package:gr0ve/features/grove/services/grove_unlock_service.dart';

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const CustomHeader(title: "CHANGELOG"),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: changelogVersions.length,
                    itemBuilder: (context, index) {
                      return _VersionPage(version: changelogVersions[index]);
                    },
                  ),
                ),

                if (changelogVersions.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(changelogVersions.length, (
                        index,
                      ) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isSelected ? 24 : 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary
                                : colors.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionPage extends StatelessWidget {
  final ChangelogVersion version;

  const _VersionPage({required this.version});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final basePersonas = [
      CounselorPersona.grover,
      CounselorPersona.aspen,
      CounselorPersona.rowan,
      CounselorPersona.sakura,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withOpacity(0.15),
                colors.primary.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.primary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Version ${version.version}',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: version.version == '1.0.0'
                          ? const _Version100EasterEgg()
                          : SizedBox(
                              height: 36,
                              width: 36.0 + (3 * 24.0),
                              child: Stack(
                                children: List.generate(basePersonas.length, (
                                  index,
                                ) {
                                  return Positioned(
                                    right: index * 24.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.surface,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          basePersonas[basePersonas.length -
                                                  1 -
                                                  index]
                                              .avatarAsset(
                                                Theme.of(context).brightness,
                                              ),
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                version.tagline,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                version.description,
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        ...version.features.map((feature) {
          return _ChangelogFeatureCard(feature: feature);
        }),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _ChangelogFeatureCard extends StatelessWidget {
  final ChangelogFeature feature;

  const _ChangelogFeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final color = feature.color ?? colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(icon: feature.icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature.title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feature.description,
            style: text.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Version100EasterEgg extends StatefulWidget {
  const _Version100EasterEgg();

  @override
  State<_Version100EasterEgg> createState() => _Version100EasterEggState();
}

class _Version100EasterEggState extends State<_Version100EasterEgg> {
  int _tapCount = 0;
  bool _isExpanded = false;

  final List<CounselorPersona> _visibleTrees = [CounselorPersona.grover];
  final List<CounselorPersona> _pool = [
    CounselorPersona.abies,
    CounselorPersona.ash,
    CounselorPersona.aspen,
    CounselorPersona.cedite,
    CounselorPersona.rowan,
    CounselorPersona.sakura,
  ];

  late List<CounselorPersona> _currentOrder;

  final List<CounselorPersona> _correctOrder = [
    CounselorPersona.abies,
    CounselorPersona.cedite,
    CounselorPersona.ash,
    CounselorPersona.grover,
    CounselorPersona.aspen,
    CounselorPersona.rowan,
    CounselorPersona.sakura,
  ];

  @override
  void initState() {
    super.initState();
    _pool.shuffle();
    _currentOrder = [];
  }

  void _handleTap() {
    if (_isExpanded) return;

    final data = UserDocCache.getCached();
    final isEligible =
        (data?['abies_unlocked'] == true) &&
        (data?['cedite_unlocked'] == true) &&
        (data?['ash_unlocked'] == true) &&
        (data?['dawn_avatar_unlocked'] == true);

    debugPrint('[EASTER EGG] Tap count: $_tapCount, Eligible: $isEligible');

    if (!isEligible) {
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _tapCount++;
      HapticFeedback.lightImpact();

      if (_tapCount < 7 && _pool.isNotEmpty) {
        _visibleTrees.add(_pool.removeAt(0));
      }

      if (_tapCount >= 7) {
        HapticFeedback.mediumImpact();
        _currentOrder = List.from(_visibleTrees);
        _isExpanded = true;
      }
    });
  }

  void _checkOrder() {
    bool isCorrect = true;
    for (int i = 0; i < _correctOrder.length; i++) {
      if (_currentOrder[i] != _correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _showPoemDialog();
    }
  }

  void _showPoemDialog() {
    GroveUnlockService.unlock();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OriginalSeedScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 36,
          width: 36.0 + (_visibleTrees.length - 1) * 20.0,
          child: Stack(
            children: List.generate(_visibleTrees.length, (index) {
              final persona = _visibleTrees[_visibleTrees.length - 1 - index];
              return Positioned(
                right: index * 20.0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      persona.avatarAsset(Theme.of(context).brightness),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ReorderableListView(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _currentOrder.removeAt(oldIndex);
            _currentOrder.insert(newIndex, item);
          });
          _checkOrder();
        },
        children: List.generate(_currentOrder.length, (index) {
          final persona = _currentOrder[index];
          return ReorderableDragStartListener(
            key: ValueKey(persona.name),
            index: index,
            child: Align(
              widthFactor: 0.75,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    persona.avatarAsset(Theme.of(context).brightness),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
