import 'package:flutter/material.dart';
import 'package:gr0ve/features/club/services/group_service.dart';
import 'package:gr0ve/models/join_request.dart';

class JoinRequestsScreen extends StatelessWidget {
  final String groupId;

  const JoinRequestsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final groupService = GroupService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pending Requests',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
          iconSize: 20,
        ),
      ),
      body: StreamBuilder<List<JoinRequest>>(
        stream: groupService.getPendingJoinRequests(groupId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No pending requests',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            itemBuilder: (context, index) {
              final request = requests[index];
              final colors = Theme.of(context).colorScheme;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colors.primary.withOpacity(0.08),
                          child: Text(
                            request.displayName[0].toUpperCase(),
                            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.displayName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                request.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, size: 14, color: colors.onSurface.withOpacity(0.3)),
                        const SizedBox(width: 6),
                        Text(
                          'Code: ${request.joinCode}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(Icons.access_time_rounded, size: 14, color: colors.onSurface.withOpacity(0.3)),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(request.requestedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              try {
                                await groupService.rejectJoinRequest(
                                  groupId,
                                  request.userId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request rejected')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Reject'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await groupService.approveJoinRequest(
                                  groupId,
                                  request.userId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Member approved!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
