import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Global pool — counselor-agnostic
    final variants = availableVariants;
    final total = variants.length;

    // Accent color from the active counselor (purely cosmetic for the sheet chrome)
    final persona = CounselorPersonaService.activePersona.value;
    final pc = persona.primary(brightness);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ── Drag handle ──────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header ───────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    _selected.assetPath(brightness),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.person_rounded, color: pc, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Picture',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$total available',
                    style: textTheme.bodySmall?.copyWith(
                      color: pc,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Grid (scrollable so it never overflows the sheet) ─
          Flexible(
            child: SingleChildScrollView(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: total,
                itemBuilder: (context, i) {
                  final v = variants[i];
                  final isActive = v.id == _selected.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = v);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? pc
                              : colors.outline.withOpacity(0.15),
                          width: isActive ? 2.5 : 1,
                        ),
                        color: isActive
                            ? pc.withOpacity(0.06)
                            : colors.surfaceVariant.withOpacity(0.3),
                      ),
                      child: Column(
                        children: [
                          // Image
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  v.assetPath(brightness),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: colors.surfaceVariant,
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: colors.onSurface.withOpacity(0.3),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Label
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isActive)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 11,
                                      color: pc,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    // Show "CounselorName · Variant" so users know
                                    // which counselor each picture belongs to
                                    v.isDefault
                                        ? v.persona.displayName
                                        : '${v.persona.displayName} · ${v.displayName}',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isActive
                                          ? pc
                                          : colors.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ), // SingleChildScrollView
          ), // Flexible

          const SizedBox(height: 24),

          // ── Confirm ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await ProfilePictureService.setVariant(_selected);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: pc,
                foregroundColor: persona.onPrimary(brightness),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Set as Profile Picture',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: persona.onPrimary(brightness),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
