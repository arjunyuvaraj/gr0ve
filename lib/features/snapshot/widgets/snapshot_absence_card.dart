import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/theme/persona_theme.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_shared.dart';

class SnapshotAbsenceCard extends StatelessWidget {
  final bool compact;
  const SnapshotAbsenceCard({super.key, this.compact = false});

  Color _statusColor(String status, ColorScheme c, BuildContext context) {
    if (status == 'Present') return context.colors.success;
    return context.colors.error;
  }

  @override
  Widget build(BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;

    return StreamBuilder<Map<String, String>>(
      stream: streamTeacherAbsences(),
      builder: (_, absSnap) {
        final absences = absSnap.data ?? {};

        final isLoading = absSnap.connectionState == ConnectionState.waiting;

        return ValueListenableBuilder<Set<String>>(
          valueListenable: StarredTeacherService.starredTeachers,
          builder: (_, starred, __) {
            if (starred.isEmpty) {
              return SnapshotTile(
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Star teachers in the Teachers tab.',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (isLoading) {
              return SnapshotTile(
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.onSurface.withOpacity(0.3),
                    ),
                  ),
                ),
              );
            }

            final sortedStarred = starred.toList()
              ..sort((a, b) {
                final statusA = resolveTeacherStatus(
                  teacherName: a,
                  absenceMap: absences,
                );
                final statusB = resolveTeacherStatus(
                  teacherName: b,
                  absenceMap: absences,
                );
                if (statusA != statusB) {
                  if (statusA != 'Present') return -1;
                  if (statusB != 'Present') return 1;
                }
                return a.compareTo(b);
              });

            return Column(
              children: sortedStarred.map((name) {
                final status = formatStatusString(
                  resolveTeacherStatus(teacherName: name, absenceMap: absences),
                );
                final col = _statusColor(status, c, ctx);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: SnapshotTile(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: compact ? 10 : 13,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 13.0 : 16.0,
                              fontWeight: FontWeight.w700,
                              color: c.onSurface,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: SnapshotPill(status, col),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
