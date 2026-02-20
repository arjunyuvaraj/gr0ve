import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/features/club/widgets/my_club_card.dart';
import 'package:gr0ve/features/club/screens/club_detail_screen.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:gr0ve/models/group.dart';
import 'package:gr0ve/features/club/services/group_service.dart';

class ClubMyClubsTab extends StatefulWidget {
  const ClubMyClubsTab({super.key});

  @override
  State<ClubMyClubsTab> createState() => _ClubMyClubsTabState();
}

class _ClubMyClubsTabState extends State<ClubMyClubsTab> {
  final GroupService _groupService = GroupService();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('Please sign in to view your groups'));
    }

    return StreamBuilder<List<Group>>(
      stream: _groupService.getUserGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final clubs = snapshot.data ?? [];

        if (clubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off_rounded,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'You haven\'t joined any groups yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse groups to find ones you\'re interested in',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: clubs.length,
          itemBuilder: (context, index) {
            final club = clubs[index];
            return MyClubCard(
              club: club,
              groupService: _groupService,
              onTap: () {
                // Clear this specific club's announcement count when tapped
                NotificationService().clearClubAnnouncementCount(club.id);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClubDetailScreen(groupId: club.id),
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
