import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/models/announcement_question.dart';
import 'package:gr0ve/features/club/services/group_service.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';

class AnnouncementQASheet extends StatefulWidget {
  final String groupId;
  final String announcementId;
  final String announcementTitle;
  final bool isModOrAdmin;
  final String? initialQuestionId;

  const AnnouncementQASheet({
    super.key,
    required this.groupId,
    required this.announcementId,
    required this.announcementTitle,
    required this.isModOrAdmin,
    this.initialQuestionId,
  });

  @override
  State<AnnouncementQASheet> createState() => _AnnouncementQASheetState();
}

class _AnnouncementQASheetState extends State<AnnouncementQASheet>
    with WidgetsBindingObserver {
  final _groupService = GroupService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final _composeController = TextEditingController();
  final _composeFocus = FocusNode();
  bool _submittingQuestion = false;

  final _replyController = TextEditingController();
  final _replyFocus = FocusNode();
  bool _sendingReply = false;

  String? _expandedQuestionId;
  final _scrollController = ScrollController();

  double _keyboardHeight = 0;

  late Stream<List<AnnouncementQuestion>> _questionsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questionsStream = _groupService.getAnnouncementQuestions(
      widget.groupId,
      widget.announcementId,
      _currentUserId ?? '',
      widget.isModOrAdmin,
    );

    if (widget.initialQuestionId != null) {
      _expandedQuestionId = widget.initialQuestionId;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _composeController.dispose();
    _composeFocus.dispose();
    _replyController.dispose();
    _replyFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final newKeyboardHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newKeyboardHeight != _keyboardHeight) {
      setState(() => _keyboardHeight = newKeyboardHeight);
    }
  }

  void _openThread(String questionId) {
    NotificationService().clearQuestionUnreadCount(questionId);
    NotificationService().clearAnnouncementQACount(
      widget.groupId,
      widget.announcementId,
    );
    NotificationService().clearUnreadCount('qa_replies');
    NotificationService().clearUnreadCount('unread_questions');
    _composeFocus.unfocus();
    _replyController.clear();
    setState(() => _expandedQuestionId = questionId);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _replyFocus.requestFocus();
    });
  }

  void _closeThread() {
    _replyFocus.unfocus();
    setState(() => _expandedQuestionId = null);
  }

  Future<void> _submitQuestion() async {
    final text = _composeController.text.trim();
    if (text.isEmpty) return;
    setState(() => _submittingQuestion = true);
    try {
      await _groupService.postQuestion(
        groupId: widget.groupId,
        announcementId: widget.announcementId,
        content: text,
      );
      _composeController.clear();
      _composeFocus.unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submittingQuestion = false);
    }
  }

  Future<void> _submitReply(String questionId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingReply = true);
    try {
      await _groupService.replyToQuestion(
        groupId: widget.groupId,
        announcementId: widget.announcementId,
        questionId: questionId,
        content: text,
      );
      _replyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Question?'),
        content: const Text(
          'This will permanently delete the question and all replies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _groupService.deleteQuestion(
        groupId: widget.groupId,
        announcementId: widget.announcementId,
        questionId: questionId,
      );
      if (_expandedQuestionId == questionId) _closeThread();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final inThread = _expandedQuestionId != null;

    final safeBottom = mq.padding.bottom;
    final sheetHeight = mq.size.height * 0.82;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: _keyboardHeight),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 40,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            _Handle(colors: colors),

            _SheetHeader(
              title: widget.isModOrAdmin ? 'All Questions' : 'My Questions',
              subtitle: widget.announcementTitle,
              isModOrAdmin: widget.isModOrAdmin,
              colors: colors,
              inThread: inThread,
              onBack: inThread ? _closeThread : null,
            ),

            Divider(height: 1, color: colors.onSurface.withOpacity(0.06)),

            Expanded(
              child: StreamBuilder<List<AnnouncementQuestion>>(
                stream: _questionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const PremiumLoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final questions = snapshot.data ?? [];

                  if (questions.isEmpty && !inThread) {
                    return _EmptyState(
                      isModOrAdmin: widget.isModOrAdmin,
                      colors: colors,
                    );
                  }

                  final displayQuestions = inThread
                      ? questions
                            .where((q) => q.id == _expandedQuestionId)
                            .toList()
                      : questions;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    itemCount: displayQuestions.length,
                    itemBuilder: (context, i) {
                      final question = displayQuestions[i];
                      return _QuestionCard(
                        key: ValueKey(question.id),
                        question: question,
                        currentUserId: _currentUserId,
                        isModOrAdmin: widget.isModOrAdmin,
                        isExpanded: inThread,
                        onTap: inThread ? null : () => _openThread(question.id),
                        onDelete: () => _deleteQuestion(question.id),
                        replyStream: inThread
                            ? _groupService.getQuestionReplies(
                                widget.groupId,
                                widget.announcementId,
                                question.id,
                              )
                            : null,
                        colors: colors,
                      );
                    },
                  );
                },
              ),
            ),

            _BottomInputBar(
              inThread: inThread,
              composeController: _composeController,
              composeFocus: _composeFocus,
              replyController: _replyController,
              replyFocus: _replyFocus,
              submitting: inThread ? _sendingReply : _submittingQuestion,
              onSend: inThread
                  ? () => _submitReply(_expandedQuestionId!)
                  : _submitQuestion,
              colors: colors,
            ),

            SizedBox(height: safeBottom > 0 ? safeBottom : 12),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _BottomInputBar — always mounted, switches between compose/reply
// =============================================================================
class _BottomInputBar extends StatelessWidget {
  final bool inThread;
  final TextEditingController composeController;
  final FocusNode composeFocus;
  final TextEditingController replyController;
  final FocusNode replyFocus;
  final bool submitting;
  final VoidCallback onSend;
  final ColorScheme colors;

  const _BottomInputBar({
    required this.inThread,
    required this.composeController,
    required this.composeFocus,
    required this.replyController,
    required this.replyFocus,
    required this.submitting,
    required this.onSend,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.onSurface.withOpacity(0.07)),
        ),
      ),
      child: Stack(
        children: [
          Visibility(
            visible: !inThread,
            maintainState: true,
            child: _InputRow(
              controller: composeController,
              focusNode: composeFocus,
              hintText: 'Ask something privately…',
              submitting: !inThread && submitting,
              onSend: onSend,
              colors: colors,
            ),
          ),
          Visibility(
            visible: inThread,
            maintainState: true,
            child: _InputRow(
              controller: replyController,
              focusNode: replyFocus,
              hintText: 'Reply to this question…',
              submitting: inThread && submitting,
              onSend: onSend,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool submitting;
  final VoidCallback onSend;
  final ColorScheme colors;

  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.submitting,
    required this.onSend,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: colors.onSurface.withOpacity(0.35),
                fontSize: 14,
              ),
              filled: true,
              fillColor: colors.onSurface.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: colors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedScale(
          scale: submitting ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Material(
            color: colors.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: submitting ? null : onSend,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: colors.onPrimary,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _QuestionCard
// =============================================================================
class _QuestionCard extends StatelessWidget {
  final AnnouncementQuestion question;
  final String? currentUserId;
  final bool isModOrAdmin;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final Stream<List<QuestionReply>>? replyStream;
  final ColorScheme colors;

  const _QuestionCard({
    super.key,
    required this.question,
    required this.currentUserId,
    required this.isModOrAdmin,
    required this.isExpanded,
    required this.onTap,
    required this.onDelete,
    required this.replyStream,
    required this.colors,
  });

  String _fmt(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inDays == 0) {
      return d.inHours > 0 ? '${d.inHours}h ago' : '${d.inMinutes}m ago';
    }
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = question.authorId == currentUserId;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: question.isAnswered
              ? colors.primary.withOpacity(0.25)
              : colors.onSurface.withOpacity(0.07),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Avatar(
                        name: question.authorName,
                        colors: colors,
                        radius: 15,
                        fontSize: 12,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isModOrAdmin
                                  ? question.authorName
                                  : isOwn
                                  ? 'You'
                                  : question.authorName,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              _fmt(question.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (question.isAnswered) ...[
                        _AnsweredBadge(),
                        const SizedBox(width: 6),
                      ],
                      StreamBuilder<Map<String, dynamic>>(
                        stream: NotificationService().unreadCountStream,
                        builder: (context, snapshot) {
                          final unread = NotificationService()
                              .getQuestionUnreadCount(question.id);
                          if (unread == 0) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      if (isOwn || isModOrAdmin)
                        _DeleteMenu(onDelete: onDelete, colors: colors),
                      if (!isExpanded)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurface.withOpacity(0.25),
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && replyStream != null) ...[
            Divider(
              height: 1,
              indent: 18,
              endIndent: 18,
              color: colors.onSurface.withOpacity(0.07),
            ),
            StreamBuilder<List<QuestionReply>>(
              stream: replyStream,
              builder: (context, snapshot) {
                final replies = snapshot.data ?? [];
                if (replies.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Text(
                      'No replies yet — type below to respond.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.35),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  itemCount: replies.length,
                  itemBuilder: (context, i) => _ReplyBubble(
                    reply: replies[i],
                    currentUserId: currentUserId,
                    colors: colors,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// _ReplyBubble
// =============================================================================
class _ReplyBubble extends StatelessWidget {
  final QuestionReply reply;
  final String? currentUserId;
  final ColorScheme colors;

  const _ReplyBubble({
    required this.reply,
    required this.currentUserId,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isOwn = reply.authorId == currentUserId;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isOwn) ...[
            _Avatar(
              name: reply.authorName,
              colors: colors,
              radius: 13,
              fontSize: 10,
              isStaff: reply.isStaff,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwn
                    ? colors.primary.withOpacity(0.1)
                    : reply.isStaff
                    ? colors.primary.withOpacity(0.06)
                    : colors.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwn ? 18 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOwn ? 'You' : reply.authorName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: reply.isStaff
                              ? colors.primary
                              : colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (reply.isStaff) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'STAFF',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Small widgets
// =============================================================================

class _Handle extends StatelessWidget {
  final ColorScheme colors;
  const _Handle({required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colors.onSurface.withOpacity(0.12),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isModOrAdmin;
  final ColorScheme colors;
  final bool inThread;
  final VoidCallback? onBack;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.isModOrAdmin,
    required this.colors,
    required this.inThread,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: inThread
                        ? colors.onSurface.withOpacity(0.06)
                        : colors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    inThread
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.question_answer_rounded,
                    size: inThread ? 14 : 16,
                    color: inThread
                        ? colors.onSurface.withOpacity(0.6)
                        : colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inThread ? 'Thread' : title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isModOrAdmin && !inThread) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 12,
                    color: colors.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Staff view — all member questions visible',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isModOrAdmin;
  final ColorScheme colors;
  const _EmptyState({required this.isModOrAdmin, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: colors.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No questions yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isModOrAdmin
                  ? 'Member questions will appear here.'
                  : 'Type below to ask the group staff privately.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnsweredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.check_circle_outline_rounded, size: 10, color: Colors.green),
        SizedBox(width: 4),
        Text(
          'Answered',
          style: TextStyle(
            color: Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DeleteMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final ColorScheme colors;
  const _DeleteMenu({required this.onDelete, required this.colors});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    icon: Icon(
      Icons.more_horiz_rounded,
      size: 18,
      color: colors.onSurface.withOpacity(0.35),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onSelected: (v) {
      if (v == 'delete') onDelete();
    },
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
            SizedBox(width: 10),
            Text('Delete', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ],
  );
}

class _Avatar extends StatelessWidget {
  final String name;
  final ColorScheme colors;
  final double radius;
  final double fontSize;
  final bool isStaff;

  const _Avatar({
    required this.name,
    required this.colors,
    required this.radius,
    required this.fontSize,
    this.isStaff = false,
  });

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: isStaff
        ? colors.primary.withOpacity(0.15)
        : colors.primary.withOpacity(0.08),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: colors.primary,
      ),
    ),
  );
}
