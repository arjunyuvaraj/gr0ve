import 'package:flutter/material.dart';
import 'package:gr0ve/components/create_club_form.dart';
import 'package:gr0ve/components/requests_list.dart';
import '../services/group_service.dart';
import '../models/group_creation_request.dart';

class ClubCreateTab extends StatefulWidget {
  const ClubCreateTab({super.key});

  @override
  State<ClubCreateTab> createState() => _ClubCreateTabState();
}

class _ClubCreateTabState extends State<ClubCreateTab> {
  final GroupService _groupService = GroupService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _groupService.requestGroupCreation(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: 'club',
      );

      _nameController.clear();
      _descriptionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Submitted for review')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Something went wrong')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Text(
            'Request a New Club',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Submit a request to create a new club. An admin will take a look.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),

          const SizedBox(height: 24),

          /// Form
          CreateClubForm(
            formKey: _formKey,
            nameController: _nameController,
            descriptionController: _descriptionController,
            isSubmitting: _isSubmitting,
            onSubmit: _submit,
          ),

          const SizedBox(height: 40),

          /// Requests
          Text(
            'Your Requests',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          RequestsList(groupService: _groupService),
        ],
      ),
    );
  }
}
