import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../models/player.dart';

class RoundHistorySheet extends StatelessWidget {
  const RoundHistorySheet({super.key, required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final players = match.players;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Round history',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height - 120,
            child: ListView.builder(
              itemCount: match.rounds.length,
              itemBuilder: (context, index) {
                final reversedIndex = match.rounds.length - 1 - index;
                final round = match.rounds[reversedIndex];
                final isCurrentRound = round.index == match.rounds.last.index;
                return Container(
                  color: isCurrentRound
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : null,
                  child: ListTile(
                    title: Text(
                      DateFormat('HH:mm:ss').format(round.createdAt),
                      style: TextStyle(
                        fontWeight: isCurrentRound
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: _roundSummaryWidget(
                      context,
                      round.index,
                      players,
                    ),
                  ),
                );
              },
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
      spans.add(
        TextSpan(
          text: delta >= 0 ? '+$delta' : '$delta',
          style: style?.copyWith(
            color: scoreColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Text.rich(TextSpan(children: spans, style: style));
  }
}
