import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/core/widgets/misc/custom_header.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';
import 'package:gr0ve/core/extensions/string_extensions.dart';

class AdminCalendarRequestsScreen extends StatelessWidget {
  const AdminCalendarRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomHeader(title: "Pending Events".capitalized),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: CalendarService.streamPublicEventRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: colors.error),
                        ),
                      );
                    }

                    final requests = snapshot.data?.docs ?? [];

                    if (requests.isEmpty) {
                      return Center(
                        child: Text(
                          'No pending event requests. Relax, you earned it.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final doc = requests[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return PublicEventRequestCard(
                          requestId: doc.id,
                          groupId: data['groupId'] as String,
                          data: data,
                        );
                      },
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
}

class PublicEventRequestCard extends StatefulWidget {
  final String requestId;
  final String groupId;
  final Map<String, dynamic> data;

  const PublicEventRequestCard({
    super.key,
    required this.requestId,
    required this.groupId,
    required this.data,
  });

  @override
  State<PublicEventRequestCard> createState() => _PublicEventRequestCardState();
}

class _PublicEventRequestCardState extends State<PublicEventRequestCard> {
  bool _isProcessing = false;

  Future<void> _handleApproval(bool approve) async {
    setState(() => _isProcessing = true);

    try {
      if (approve) {
        await CalendarService.approvePublicEventRequest(
          widget.groupId,
          widget.requestId,
          widget.data,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event approved and added to BCA calendar'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await CalendarService.rejectPublicEventRequest(
          widget.groupId,
          widget.requestId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final title = widget.data['title'] as String;
    final description = widget.data['description'] as String?;
    final groupName = widget.data['groupName'] as String;
    final date = (widget.data['date'] as Timestamp).toDate();
    final isAllDay = widget.data['isAllDay'] as bool? ?? true;
    final requestedAt = widget.data['requestedAt'] as Timestamp?;
    final status = widget.data['status'] as String? ?? 'pending';

    final dateStr = DateFormat('MMM dd, yyyy').format(date);
    String timeStr = '';
    if (!isAllDay) {
      final startTime = widget.data['startTime'] != null
          ? (widget.data['startTime'] as Timestamp).toDate()
          : null;
      final endTime = widget.data['endTime'] != null
          ? (widget.data['endTime'] as Timestamp).toDate()
          : null;

      if (startTime != null) {
        timeStr = DateFormat('h:mm a').format(startTime);
        if (endTime != null) {
          timeStr += ' - ${DateFormat('h:mm a').format(endTime)}';
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // could expand or show details
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.onSurface.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'pending'
                            ? colors.primaryContainer
                            : status == 'approved'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'pending'
                              ? colors.onPrimaryContainer
                              : status == 'approved'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Group
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 14,
                      color: colors.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      groupName,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date & time
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: text.bodyMedium?.copyWith(color: colors.onSurface),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),

                // Description
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurface.withAlpha(180),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Requested at
                if (requestedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Requested ${_formatTimeAgo(requestedAt.toDate())}',
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurface.withAlpha(120),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Action buttons
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleApproval(false),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.errorContainer,
                            foregroundColor: colors.onErrorContainer,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleApproval(true),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }
}
