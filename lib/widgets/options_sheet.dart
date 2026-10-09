import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OptionsSheet extends StatelessWidget {
  const OptionsSheet({
    super.key,
    required this.onAddPlayer,
    required this.onResetMatch,
    required this.onNewMatch,
    required this.onNewRace,
    required this.onShowHistory,
    this.isRaceMode = false,
  });

  final VoidCallback onAddPlayer;
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
                      color: isRaceMode ? Colors.white : null,
                    ),
              ),
            ),
            if (!isRaceMode)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add new player'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                  onAddPlayer();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.sports_esports_rounded,
                color: isRaceMode ? const Color(0xFFD4AF37) : null,
              ),
              title: Text(
                'New Race',
                style: TextStyle(color: isRaceMode ? Colors.white : null),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                onNewRace();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.add,
                color: isRaceMode ? const Color(0xFFD4AF37) : null,
              ),
              title: Text(
                'Đánh Đền',
                style: TextStyle(color: isRaceMode ? Colors.white : null),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                onNewMatch();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.restart_alt,
                color: isRaceMode ? const Color(0xFFD4AF37) : null,
              ),
              title: Text(
                'Reset match',
                style: TextStyle(color: isRaceMode ? Colors.white : null),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                onResetMatch();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: isRaceMode ? const Color(0xFFD4AF37) : null,
              ),
              title: Text(
                'Show history',
                style: TextStyle(color: isRaceMode ? Colors.white : null),
              ),
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
