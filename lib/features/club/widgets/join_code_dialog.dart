import 'package:flutter/material.dart';
import 'package:gr0ve/features/club/services/group_service.dart';

class JoinCodeDialog extends StatefulWidget {
  const JoinCodeDialog({super.key});

  @override
  State<JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<JoinCodeDialog> {
  final GroupService _groupService = GroupService();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a join code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _groupService.requestToJoin(code);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Join request submitted! Waiting for admin approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join with Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the 6-character join code provided by the club admin:',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Join Code',
              border: OutlineInputBorder(),
              hintText: 'ABC123',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            onSubmitted: (_) => _submitCode(),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Your request will need to be approved by an admin.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitCode,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
