import 'package:flutter/material.dart';

import '../models/match.dart';
import '../models/player.dart';

class RoundHistorySheet extends StatelessWidget {
  const RoundHistorySheet({
    super.key,
    required this.match,
    required this.onNextRound,
  });

  final MatchModel match;
  final VoidCallback onNextRound;

  bool get _canGoNextRound {
    if (match.rounds.isEmpty) return false;
    final round = match.rounds.last;
    final totalZero = round.roundTotal == 0;
    final somePlayerScored = match.players
        .any((p) => round.totalForPlayer(p.id) != 0);
    return totalZero && somePlayerScored;
  }

  @override
  Widget build(BuildContext context) {
    final players = match.players;
    final canGoNext = _canGoNextRound;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Round history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            height: 240,
            child: ListView.builder(
              itemCount: match.rounds.length,
              itemBuilder: (context, index) {
                final reversedIndex = match.rounds.length - 1 - index;
                final round = match.rounds[reversedIndex];
                final isCurrentRound = round.index == match.rounds.last.index;
                return Container(
                  color: isCurrentRound
                      ? Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.5)
                      : null,
                  child: ListTile(
                    title: Text(
                      'Round ${round.index}',
                      style: TextStyle(
                        fontWeight:
                            isCurrentRound ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: _roundSummaryWidget(
                        context, round.index, players),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: canGoNext ? onNextRound : null,
                  child: const Text('Next round'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundSummaryWidget(
    BuildContext context,
    int roundIndex,
    List<Player> players,
  ) {
    final round = match.rounds.firstWhere((r) => r.index == roundIndex);
    final style = Theme.of(context).textTheme.bodyMedium;
    final spans = <InlineSpan>[];
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      final delta = round.totalForPlayer(p.id);
      if (i > 0) {
        spans.add(TextSpan(text: ' • ', style: style));
      }
      spans.add(TextSpan(text: '${p.name}: ', style: style));
      final scoreColor = delta > 0
          ? Colors.green
          : delta < 0
              ? Colors.red
              : Colors.grey;
      spans.add(TextSpan(
        text: delta >= 0 ? '+$delta' : '$delta',
        style: style?.copyWith(
          color: scoreColor,
          fontWeight: FontWeight.w600,
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans, style: style));
  }
}

