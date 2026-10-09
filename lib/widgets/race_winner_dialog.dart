import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player.dart';

class RaceWinnerDialog extends StatelessWidget {
  const RaceWinnerDialog({
    super.key,
    required this.winner,
    required this.loser,
    required this.winnerScore,
    required this.loserScore,
    required this.raceTarget,
    required this.onRematch,
    required this.onNewRace,
  });

  final Player winner;
  final Player loser;
  final int winnerScore;
  final int loserScore;
  final int raceTarget;
  final VoidCallback onRematch;
  final VoidCallback onNewRace;

  static Future<void> show(
    BuildContext context, {
    required Player winner,
    required Player loser,
    required int winnerScore,
    required int loserScore,
    required int raceTarget,
    required VoidCallback onRematch,
    required VoidCallback onNewRace,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RaceWinnerDialog(
        winner: winner,
        loser: loser,
        winnerScore: winnerScore,
        loserScore: loserScore,
        raceTarget: raceTarget,
        onRematch: onRematch,
        onNewRace: onNewRace,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF130E2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Color(0xFF00E5FF),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    winner.color.withValues(alpha: 0.35),
                    winner.color.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: winner.color,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: winner.color,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'VICTORY!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              winner.name,
              style: TextStyle(
                color: winner.color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Won the Race to $raceTarget',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            // Score comparison card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    winner.name,
                    style: TextStyle(
                      color: winner.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$winnerScore - $loserScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loser.name,
                    style: TextStyle(
                      color: loser.color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    onNewRace();
                  },
                  child: const Text('New Race'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text('Rematch'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0D0A1C),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    onRematch();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
