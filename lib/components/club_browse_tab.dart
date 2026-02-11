import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_group_card.dart';
import 'package:gr0ve/components/join_with_code_card.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/features/club/group.dart';

import '../features/beta/groups/group_service.dart';
import './join_code_dialog.dart';

class ClubBrowseTab extends StatefulWidget {
  const ClubBrowseTab({super.key});

  @override
  State<ClubBrowseTab> createState() => _ClubBrowseTabState();
}

class _ClubBrowseTabState extends State<ClubBrowseTab> {
  final GroupService _groupService = GroupService();
  final TextEditingController _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  void _openJoinDialog() {
    showDialog(context: context, builder: (_) => const JoinCodeDialog());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return StreamBuilder<List<Group>>(
      stream: _groupService.getActiveGroups(type: GroupType.club),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Something went wrong. Clubs remain elusive.",
              style: context.text.bodyMedium,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final clubs = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            /// Optional explicit join card
            JoinWithCodeCard(
              controller: _joinCodeController,
              onJoinPressed: _openJoinDialog,
            ),

            const SizedBox(height: 20),

            if (clubs.isEmpty) ...[
              const SizedBox(height: 40),
              Icon(
                Icons.groups_outlined,
                size: 64,
                color: colors.onSurface.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                "No clubs yet",
                textAlign: TextAlign.center,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                "Either nobody made one or nobody invited you.",
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: colors.onSurface.withAlpha(140),
                ),
              ),
            ] else ...[
              Text(
                "Available clubs",
                style: context.text.titleSmall?.copyWith(
                  color: colors.onSurface.withAlpha(160),
                ),
              ),
              const SizedBox(height: 12),

              ...clubs.map((club) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomGroupCard(
                    name: club.name,
                    description: club.description,
                    onTap: _openJoinDialog,
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
