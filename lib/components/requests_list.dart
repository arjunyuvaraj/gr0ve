import 'package:flutter/material.dart';
import 'package:gr0ve/components/request_card.dart';
import 'package:gr0ve/models/group_creation_request.dart';
import 'package:gr0ve/services/group_service.dart';

class RequestsList extends StatelessWidget {
  final GroupService groupService;

  const RequestsList({required this.groupService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<GroupCreationRequest>>(
      stream: groupService.getUserCreationRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nothing submitted yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }

        return Column(
          children: requests
              .map((request) => RequestCard(request: request))
              .toList(),
        );
      },
    );
  }
}
