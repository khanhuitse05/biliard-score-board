import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OptionsSheet extends StatefulWidget {
  const OptionsSheet({
    super.key,
    required this.onResetMatch,
    required this.onNewMatch,
    required this.onShowHistory,
  });

  final VoidCallback onResetMatch;
  final VoidCallback onNewMatch;
  final VoidCallback onShowHistory;

  @override
  State<OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<OptionsSheet> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Options',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset match'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                widget.onResetMatch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New match'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                widget.onNewMatch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Show history'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                widget.onShowHistory();
              },
            ),
          ],
        ),
      ),
    );
  }
}
