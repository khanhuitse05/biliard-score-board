import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OptionsSheet extends StatelessWidget {
  const OptionsSheet({
    super.key,
    this.onAddPlayer,
    required this.onResetMatch,
    required this.onNewMatch,
    required this.onNewRace,
    required this.onShowHistory,
    this.isRaceMode = false,
  });

  final VoidCallback? onAddPlayer;
  final VoidCallback onResetMatch;
  final VoidCallback onNewMatch;
  final VoidCallback onNewRace;
  final VoidCallback onShowHistory;
  final bool isRaceMode;

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
            if (!isRaceMode && onAddPlayer != null)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add new player'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                  onAddPlayer!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.sports_esports_rounded),
              title: const Text('New Race'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                onNewRace();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Đánh Đền'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                onNewMatch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset match'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                onResetMatch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Show history'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                onShowHistory();
              },
            ),
          ],
        ),
      ),
    );
  }
}
