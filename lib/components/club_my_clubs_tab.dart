import 'package:flutter/material.dart';
import 'package:gr0ve/components/my_club_card.dart';
import 'package:gr0ve/pages/club_detail_screen.dart';
import '../services/group_service.dart';
import '../models/group.dart';

class ClubMyClubsTab extends StatelessWidget {
  const ClubMyClubsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final groupService = GroupService();

    return StreamBuilder<List<Group>>(
      stream: groupService.getUserGroups(type: GroupType.club),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        final clubs = snapshot.data ?? [];

        if (clubs.isEmpty) {
          return const _EmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: clubs.length,
          itemBuilder: (context, index) {
            final club = clubs[index];

            return MyClubCard(
              club: club,
              groupService: groupService,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClubDetailScreen(groupId: club.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No clubs yet.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'You can fix that.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
