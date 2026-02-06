import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResetMatchDialog extends StatelessWidget {
  const ResetMatchDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const ResetMatchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset match'),
      content: const Text(
        'Reset all scores for this match? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
