import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/components/custom_secondary_button.dart';
import 'package:gr0ve/components/custom_text_field.dart';
import 'package:gr0ve/features/links/link_service.dart';

class AddLinkDialog extends StatefulWidget {
  final Function(String title, String url, String iconKey, Color color) onAdd;
  final QuickLink? editingLink; // Add this for editing
  const AddLinkDialog({super.key, required this.onAdd, this.editingLink});

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  late TextEditingController titleController;
  late TextEditingController urlController;
  late Color selectedColor;
  late String selectedIconKey;

  final availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.teal,
  ];

  final List<String> availableIconKeys = [
    'link',
    'school',
    'book',
    'calendar',
    'map',
    'shopping',
    'home',
    'favorite',
    'email',
    'phone',
    'music',
    'video',
    'games',
    'work',
    'sports',
    'description',
    'directions_bus',
    'event_available',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing values if editing
    if (widget.editingLink != null) {
      titleController = TextEditingController(text: widget.editingLink!.title);
      final url = widget.editingLink!.url;
      // Remove https://www. prefix for display
      final displayUrl = url.startsWith('https://www.')
          ? url.substring(12)
          : url;
      urlController = TextEditingController(text: displayUrl);
      selectedColor = widget.editingLink!.color;
      selectedIconKey = widget.editingLink!.iconKey;
    } else {
      titleController = TextEditingController();
      urlController = TextEditingController();
      selectedColor = Colors.blue;
      selectedIconKey = 'link';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    urlController.dispose();
    super.dispose();
  }

  IconData _getIconData(String key) {
    return QuickLink(
      id: 'temp',
      title: '',
      url: '',
      iconKey: key,
      color: Colors.blue,
    ).icon;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.editingLink != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEditing ? 'Edit Link' : 'Add New Link',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomTextField(
              hintText: 'Title',
              controller: titleController,
              obscureText: false,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: 'URL (https://www. already included)',
              controller: urlController,
              obscureText: false,
            ),
            const SizedBox(height: 24),
            Text(
              "Color",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 156,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: availableColors.map((c) {
                  final isSelected = c == selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.black.withOpacity(0.3)
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Icon",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 250,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: availableIconKeys.map((iconKey) {
                  final isSelected = iconKey == selectedIconKey;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIconKey = iconKey),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withOpacity(0.2)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? selectedColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getIconData(iconKey),
                        color: isSelected ? selectedColor : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPrimaryButton(
                label: isEditing ? "Save Changes" : "Add Link",
                onTap: () {
                  String title = titleController.text;
                  String url = urlController.text;
                  if (title.trim().isEmpty || url.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  widget.onAdd(
                    title.trim(),
                    url.startsWith('http')
                        ? url.trim()
                        : "https://www.${url.trim()}",
                    selectedIconKey,
                    selectedColor,
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              CustomSecondaryButton(
                onTap: () => Navigator.pop(context),
                label: 'Cancel',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
