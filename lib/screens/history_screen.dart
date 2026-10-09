import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.matches,
    required this.currentMatchId,
  });

  final List<MatchModel> matches;
  final String? currentMatchId;

  @override
  Widget build(BuildContext context) {
    final sortedMatches = List<MatchModel>.from(matches)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        itemCount: sortedMatches.length,
        itemBuilder: (context, index) {
          final match = sortedMatches[index];
          final isCurrent = match.id == currentMatchId;
          final isRace = match.isRaceMode;

          return ListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRace
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                        : Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isRace
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                          : Colors.purple.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isRace ? 'Race to ${match.raceTarget}' : 'Đánh Đền',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isRace ? const Color(0xFF00E5FF) : Colors.purple[300],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('y d MMM - HH:mm').format(match.createdAt.toLocal()),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_summaryForMatch(match)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(match);
            },
          );
        },
      ),
    );
  }

  String _summaryForMatch(MatchModel match) {
    if (match.isRaceMode) {
      final winner = match.raceWinner;
      return match.players.map((p) {
        final score = match.scoreFor(p.id);
        final isWinner = winner != null && winner.id == p.id;
        return '${p.name}: $score${isWinner ? ' 🏆' : ''}';
      }).join('   •   ');
    }
    return match.players
        .map((p) => '${p.name}: ${match.scoreFor(p.id)}')
        .join('\n');
  }
}

