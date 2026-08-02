import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/core/widgets/images/remote_asset_image.dart';
import 'package:gr0ve/features/account/services/profile_picture_service.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

class ProfilePicturePickerSheet extends StatefulWidget {
  const ProfilePicturePickerSheet({super.key});

  @override
  State<ProfilePicturePickerSheet> createState() =>
      _ProfilePicturePickerSheetState();
}

class _ProfilePicturePickerSheetState extends State<ProfilePicturePickerSheet> {
  late ProfileVariant _selected;

  @override
  void initState() {
    super.initState();
    _selected = ProfilePictureService.activeVariant.value;

    ProfilePictureService.activeVariant.addListener(_onVariantChanged);
  }

  @override
  void dispose() {
    ProfilePictureService.activeVariant.removeListener(_onVariantChanged);
    super.dispose();
  }

  void _onVariantChanged() {
    if (mounted) {
      setState(() => _selected = ProfilePictureService.activeVariant.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final variants = availableVariants;
    final persona = CounselorPersonaService.activePersona.value;
    final pc = persona.primary(brightness);

    final grover = variants
        .where(
          (v) =>
              v.persona == CounselorPersona.grover &&
              !v.key.startsWith('academy_') &&
              !v.key.startsWith('field_day_') &&
              !['dawn', 'newton', 'darwin', 'salix', 'london'].contains(v.key),
        )
        .toList();
    final aspen = variants
        .where(
          (v) =>
              v.persona == CounselorPersona.aspen &&
              !v.key.startsWith('academy_'),
        )
        .toList();
    final rowan = variants
        .where(
          (v) =>
              v.persona == CounselorPersona.rowan &&
              !v.key.startsWith('academy_'),
        )
        .toList();
    final sakura = variants
        .where(
          (v) =>
              v.persona == CounselorPersona.sakura &&
              !v.key.startsWith('academy_'),
        )
        .toList();
    final hidden = variants.where((v) => v.persona.isHidden).toList();
    final story = variants
        .where(
          (v) =>
              ['dawn', 'newton', 'darwin', 'salix', 'london'].contains(v.key),
        )
        .toList();
    final academy = variants
        .where((v) => v.key.startsWith('academy_'))
        .toList();
    final fieldDay = variants
        .where((v) => v.key.startsWith('field_day_'))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    color: pc,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Identity',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Choose how you appear in the grove',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.isNotEmpty) ...[
                    _sectionHeader(
                      'STORY REWARDS',
                      Icons.auto_awesome_rounded,
                      Colors.amber,
                    ),
                    _variantGrid(story, pc, colors, brightness),
                    const SizedBox(height: 20),
                  ],

                  if (academy.isNotEmpty) ...[
                    _sectionHeader(
                      'ACADEMY PRIDE',
                      Icons.school_rounded,
                      const Color(0xFF3498DB),
                    ),
                    _variantGrid(academy, pc, colors, brightness),
                    const SizedBox(height: 20),
                  ],

                  if (fieldDay.isNotEmpty) ...[
                    _sectionHeader(
                      'FIELD DAY TREE',
                      Icons.park_rounded,
                      const Color(0xFFD4A912),
                    ),
                    _variantGrid(fieldDay, pc, colors, brightness),
                    const SizedBox(height: 20),
                  ],

                  _sectionHeader(
                    'GROVER',
                    Icons.forest_rounded,
                    CounselorPersona.grover.primary(brightness),
                  ),
                  _variantGrid(grover, pc, colors, brightness),
                  const SizedBox(height: 20),

                  _sectionHeader(
                    'ASPEN',
                    Icons.wb_sunny_rounded,
                    CounselorPersona.aspen.primary(brightness),
                  ),
                  _variantGrid(aspen, pc, colors, brightness),
                  const SizedBox(height: 20),

                  _sectionHeader(
                    'ROWAN',
                    Icons.eco_rounded,
                    CounselorPersona.rowan.primary(brightness),
                  ),
                  _variantGrid(rowan, pc, colors, brightness),
                  const SizedBox(height: 20),

                  _sectionHeader(
                    'SAKURA',
                    Icons.flutter_dash_rounded,
                    CounselorPersona.sakura.primary(brightness),
                  ),
                  _variantGrid(sakura, pc, colors, brightness),
                  const SizedBox(height: 20),

                  if (hidden.isNotEmpty) ...[
                    _sectionHeader(
                      'ANCIENT TREES',
                      Icons.history_edu_rounded,
                      Colors.purpleAccent,
                    ),
                    _variantGrid(hidden, pc, colors, brightness),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ProfilePictureService.setVariant(_selected);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pc,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: const Text(
                  'Save Identity',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: color.withOpacity(0.9)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantGrid(
    List<ProfileVariant> variants,
    Color pc,
    ColorScheme colors,
    Brightness brightness,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 96,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88,
      ),
      itemCount: variants.length,
      itemBuilder: (context, i) {
        final v = variants[i];
        final isActive = v.id == _selected.id;
        final sectionColor = v.key.startsWith('academy_')
            ? const Color(0xFF3498DB)
            : v.key.startsWith('field_day_')
            ? const Color(0xFFD4A912)
            : v.persona.primary(brightness);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selected = v);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? sectionColor
                    : colors.onSurface.withOpacity(0.08),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: sectionColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
              color: isActive ? sectionColor.withOpacity(0.08) : colors.surface,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: RemoteAssetImage(
                        v.assetPath(brightness),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
                  child: Text(
                    v.key.startsWith('academy_')
                        ? v.key.split('_').last.toUpperCase()
                        : v.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      color: isActive
                          ? sectionColor
                          : colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
