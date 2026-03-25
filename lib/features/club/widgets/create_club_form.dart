import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class CreateClubForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const CreateClubForm({
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  hintText: 'e.g. Robotics Group',
                ),
                validator: (v) => v == null || v.trim().length < 3
                    ? 'Name is too short'
                    : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this group about?',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Description needs more detail'
                    : null,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      context.colors.primary.withAlpha(150),
                    ),
                  ),
                  onPressed: isSubmitting ? null : onSubmit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit for review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
