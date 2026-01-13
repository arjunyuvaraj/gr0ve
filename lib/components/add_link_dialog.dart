import 'package:flutter/material.dart';
import 'package:gr0ve/components/custom_primary_button.dart';
import 'package:gr0ve/components/custom_secondary_button.dart';
import 'package:gr0ve/components/custom_text_field.dart';

class AddLinkDialog extends StatefulWidget {
  final Function(String title, String url, IconData icon, Color color) onAdd;

  const AddLinkDialog({super.key, required this.onAdd});

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  String title = '';
  String url = '';
  Color selectedColor = Colors.blue;
  IconData selectedIcon = Icons.link;

  final availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.teal,
  ];

  final availableIcons = [
    Icons.link,
    Icons.school,
    Icons.code,
    Icons.calendar_today,
    Icons.map,
    Icons.restaurant,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Add New Link',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomTextField(
              hintText: 'Title',
              controller: TextEditingController(),
              onChange: (v) => title = v,
              obscureText: false,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: 'URL',
              controller: TextEditingController(),
              onChange: (v) => url = v,
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
              width: 156,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: availableIcons.map((i) {
                  final isSelected = i == selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = i),
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
                        i,
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
                label: "Add Link",
                onTap: () {
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
                    url.trim(),
                    selectedIcon,
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
