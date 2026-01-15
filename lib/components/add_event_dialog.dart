import 'package:flutter/material.dart';
import 'package:gr0ve/services/calendar_service.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;

  const AddEventDialog({super.key, required this.selectedDate});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'homework';
  bool _isAllDay = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _errorMessage;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'test', 'label': 'Test', 'icon': Icons.assignment},
    {'value': 'quiz', 'label': 'Quiz', 'icon': Icons.quiz},
    {'value': 'homework', 'label': 'Homework', 'icon': Icons.book},
    {'value': 'project', 'label': 'Project', 'icon': Icons.work},
    {'value': 'social', 'label': 'Social', 'icon': Icons.people},
    {'value': 'other', 'label': 'Other', 'icon': Icons.event},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
        _errorMessage = null;
      });
    }
  }

  void _saveEvent() {
    setState(() => _errorMessage = null);

    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a title');
      return;
    }

    if (!_isAllDay && _startTime == null) {
      setState(() => _errorMessage = 'Please select a start time');
      return;
    }

    final now = DateTime.now();
    final eventDate = widget.selectedDate;

    DateTime? startTime;
    DateTime? endTime;

    if (!_isAllDay && _startTime != null) {
      startTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      if (_endTime != null) {
        endTime = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }
    }

    final event = CalendarEvent(
      id: 'personal_${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      date: eventDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: 'personal',
      personalCategory: _selectedCategory,
      isAllDay: _isAllDay,
      startTime: startTime,
      endTime: endTime,
    );

    CalendarService.addPersonalEvent(event);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Event added successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Event',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    color: colors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.errorContainer.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colors.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onErrorContainer,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title Field
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Title',
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.onSurface.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.onSurface.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                  ),
                  style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.onSurface.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.onSurface.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                  ),
                  style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Category Label
                Text(
                  'Category',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    color: colors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Category Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.onSurface.withOpacity(0.2),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      errorBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    dropdownColor: colors.surface,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 28,
                      color: colors.onSurface,
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['value'] as String,
                        child: Row(
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 20,
                              color: colors.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text(cat['label'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // All Day Toggle
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Day',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: _isAllDay,
                          onChanged: (value) {
                            setState(() {
                              _isAllDay = value;
                              _errorMessage = null;
                            });
                          },
                          activeColor: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time Pickers
                if (!_isAllDay) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, true),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colors.primary,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _startTime != null
                                      ? _startTime!.format(context)
                                      : 'Start Time',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, false),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colors.primary,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _endTime != null
                                      ? _endTime!.format(context)
                                      : 'End Time',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimary,
                        ),
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
