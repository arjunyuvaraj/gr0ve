import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gr0ve/features/club/services/group_service.dart';

class PostAnnouncementDialog extends StatefulWidget {
  final String groupId;

  const PostAnnouncementDialog({super.key, required this.groupId});

  @override
  State<PostAnnouncementDialog> createState() => _PostAnnouncementDialogState();
}

class _PostAnnouncementDialogState extends State<PostAnnouncementDialog>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();

  late final TabController _tabController;

  bool _isPinned = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  // ─── formatting helpers ──────────────────────────────────

  void _wrapSelection(String open, String close) {
    final ctrl = _contentController;
    final sel = ctrl.selection;

    if (!sel.isValid || sel.baseOffset < 0) {
      final cursor = ctrl.text.length;
      ctrl.value = ctrl.value.copyWith(
        text: '${ctrl.text}$open$close',
        selection: TextSelection.collapsed(offset: cursor + open.length),
      );
      return;
    }

    final selected = sel.textInside(ctrl.text);
    final newText = ctrl.text.replaceRange(
      sel.start,
      sel.end,
      '$open$selected$close',
    );
    ctrl.value = ctrl.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start + open.length,
        extentOffset: sel.start + open.length + selected.length,
      ),
    );
    _contentFocusNode.requestFocus();
  }

  void _insertLinePrefix(String prefix) {
    final ctrl = _contentController;
    final sel = ctrl.selection;
    final text = ctrl.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    final before = text.substring(0, start);
    final selected = text.substring(start, end);
    final after = text.substring(end);

    final prefixed = selected.isEmpty
        ? prefix
        : selected.split('\n').map((l) => '$prefix$l').join('\n');

    ctrl.value = ctrl.value.copyWith(
      text: '$before$prefixed$after',
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + prefixed.length,
      ),
    );
    _contentFocusNode.requestFocus();
  }

  void _applyBold() => _wrapSelection('**', '**');
  void _applyItalic() => _wrapSelection('_', '_');
  void _applyUnderline() => _wrapSelection('<u>', '</u>');
  void _applyStrike() => _wrapSelection('~~', '~~');
  void _applyCode() => _wrapSelection('`', '`');
  void _applyQuote() => _insertLinePrefix('> ');
  void _applyBullet() => _insertLinePrefix('• ');
  void _applyNumbered() => _insertLinePrefix('1. ');

  Future<void> _applyLink() async {
    final ctrl = _contentController;
    final sel = ctrl.selection;
    final selectedText = sel.isValid ? sel.textInside(ctrl.text) : '';

    final urlCtrl = TextEditingController();
    final labelCtrl = TextEditingController(text: selectedText);

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insert Link',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _linkField('Label', labelCtrl, Icons.label_outline_rounded),
              const SizedBox(height: 12),
              _linkField(
                'URL',
                urlCtrl,
                Icons.link_rounded,
                hint: 'https://...',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final url = urlCtrl.text.trim();
                      final label = labelCtrl.text.trim();
                      if (url.isEmpty) return;
                      Navigator.of(ctx).pop();

                      final linkMd = '[${label.isEmpty ? url : label}]($url)';
                      if (sel.isValid && sel.start != sel.end) {
                        final newText = ctrl.text.replaceRange(
                          sel.start,
                          sel.end,
                          linkMd,
                        );
                        ctrl.value = ctrl.value.copyWith(
                          text: newText,
                          selection: TextSelection.collapsed(
                            offset: sel.start + linkMd.length,
                          ),
                        );
                      } else {
                        final cursor = sel.isValid
                            ? sel.baseOffset
                            : ctrl.text.length;
                        final before = ctrl.text.substring(0, cursor);
                        final after = ctrl.text.substring(cursor);
                        ctrl.value = ctrl.value.copyWith(
                          text: '$before$linkMd$after',
                          selection: TextSelection.collapsed(
                            offset: cursor + linkMd.length,
                          ),
                        );
                      }
                      _contentFocusNode.requestFocus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Insert',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // ─── submit ──────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await _groupService.postAnnouncement(
        groupId: widget.groupId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        isPinned: _isPinned,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement posted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                Text(
                  'Post Announcement',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep the mild chaos organized.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ───────────────────────────────────
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Something important...',
                    prefixIcon: const Icon(Icons.title_rounded),
                    filled: true,
                    fillColor: cs.onSurface.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a title'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Write / Preview tabs ─────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab bar (Write | Preview)
                      _WritePreviewTabBar(controller: _tabController, cs: cs),

                      Divider(
                        height: 1,
                        thickness: 1,
                        color: cs.onSurface.withOpacity(0.07),
                      ),

                      SizedBox(
                        height: 260,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // ── Write tab ───────────────────
                            Column(
                              children: [
                                _FormattingToolbar(
                                  onBold: _applyBold,
                                  onItalic: _applyItalic,
                                  onUnderline: _applyUnderline,
                                  onStrike: _applyStrike,
                                  onLink: _applyLink,
                                  onBullet: _applyBullet,
                                  onNumbered: _applyNumbered,
                                  onQuote: _applyQuote,
                                  onCode: _applyCode,
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: cs.onSurface.withOpacity(0.07),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _contentController,
                                    focusNode: _contentFocusNode,
                                    decoration: const InputDecoration(
                                      hintText: 'Write your announcement...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(16),
                                    ),
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Please enter content'
                                        : null,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    10,
                                  ),
                                  child: Text(
                                    'Supports Markdown · **bold** · _italic_ · [link](url)',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.3),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ── Preview tab ──────────────────
                            _MarkdownPreview(
                              content: _contentController.text,
                              cs: cs,
                              tt: tt,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Pin toggle ───────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'Pin this announcement',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Pinned announcements appear at the top',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                    value: _isPinned,
                    onChanged: (v) => setState(() => _isPinned = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    activeColor: cs.primary,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Actions ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Post',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Write / Preview tab bar
// ============================================================

class _WritePreviewTabBar extends StatelessWidget {
  final TabController controller;
  final ColorScheme cs;

  const _WritePreviewTabBar({required this.controller, required this.cs});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: const [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 16),
              SizedBox(width: 6),
              Text('Write'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_rounded, size: 16),
              SizedBox(width: 6),
              Text('Preview'),
            ],
          ),
        ),
      ],
      labelColor: cs.primary,
      unselectedLabelColor: cs.onSurface.withOpacity(0.4),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: cs.primary, width: 2),
        insets: const EdgeInsets.symmetric(horizontal: 24),
      ),
      dividerColor: Colors.transparent,
    );
  }
}

// ============================================================
//  Live Markdown preview panel
// ============================================================

class _MarkdownPreview extends StatelessWidget {
  final String content;
  final ColorScheme cs;
  final TextTheme tt;

  const _MarkdownPreview({
    required this.content,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 36,
              color: cs.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing to preview yet',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.35),
              ),
            ),
          ],
        ),
      );
    }

    final mdStyle = MarkdownStyleSheet(
      p: tt.bodyMedium?.copyWith(
        color: cs.onSurface.withOpacity(0.8),
        height: 1.5,
      ),
      strong: tt.bodyMedium?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.5,
      ),
      em: tt.bodyMedium?.copyWith(
        color: cs.onSurface.withOpacity(0.8),
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
      del: tt.bodyMedium?.copyWith(
        color: cs.onSurface.withOpacity(0.5),
        decoration: TextDecoration.lineThrough,
        height: 1.5,
      ),
      a: tt.bodyMedium?.copyWith(
        color: cs.primary,
        decoration: TextDecoration.underline,
        height: 1.5,
      ),
      code: tt.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: cs.primary,
        backgroundColor: cs.primary.withOpacity(0.08),
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: cs.primary.withOpacity(0.4), width: 3),
        ),
        color: cs.primary.withOpacity(0.04),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
      ),
      blockquote: tt.bodyMedium?.copyWith(
        color: cs.onSurface.withOpacity(0.65),
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
      listBullet: tt.bodyMedium?.copyWith(color: cs.primary),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(
        data: content,
        styleSheet: mdStyle,
        shrinkWrap: true,
        softLineBreak: true,
        onTapLink: (text, href, title) async {
          if (href == null) return;
          final uri = Uri.tryParse(href);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}

// ============================================================
//  Formatting Toolbar
// ============================================================

class _FormattingToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onStrike;
  final VoidCallback onBullet;
  final VoidCallback onNumbered;
  final AsyncCallback onLink;
  final VoidCallback onQuote;
  final VoidCallback onCode;

  const _FormattingToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onStrike,
    required this.onBullet,
    required this.onNumbered,
    required this.onLink,
    required this.onQuote,
    required this.onCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              onTap: onBold,
            ),
            _ToolbarButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              onTap: onItalic,
            ),
            _ToolbarButton(
              icon: Icons.format_underline_rounded,
              tooltip: 'Underline',
              onTap: onUnderline,
            ),
            _ToolbarButton(
              icon: Icons.format_strikethrough_rounded,
              tooltip: 'Strikethrough',
              onTap: onStrike,
            ),
            _ToolbarDivider(),
            _ToolbarButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet list',
              onTap: onBullet,
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered_rounded,
              tooltip: 'Numbered list',
              onTap: onNumbered,
            ),
            _ToolbarDivider(),
            _ToolbarButton(
              icon: Icons.link_rounded,
              tooltip: 'Insert link',
              onTap: onLink,
            ),
            _ToolbarButton(
              icon: Icons.format_quote_rounded,
              tooltip: 'Block quote',
              onTap: onQuote,
            ),
            _ToolbarButton(
              icon: Icons.code_rounded,
              tooltip: 'Inline code',
              onTap: onCode,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
    );
  }
}
