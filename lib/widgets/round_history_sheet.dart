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
    // Exclude the current (last) round from the history list.
    final historyRounds = match.rounds
        .where((r) => r.index != match.rounds.last.index)
        .toList();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
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
            child: historyRounds.isEmpty
                ? const Center(child: Text('No round history'))
                : ListView.builder(
                    itemCount: historyRounds.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = historyRounds.length - 1 - index;
                      final round = historyRounds[reversedIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                DateFormat('mm:ss').format(round.createdAt),
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            Expanded(
                              child: _roundSummaryWidget(
                                context,
                                round.index,
                                players,
                              ),
                            ),
                          ],
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
    final style = Theme.of(context).textTheme.bodyLarge;
    final spans = <InlineSpan>[];
    // Only show players who had a non-zero score change this round.
    final activePlayers = players
        .where((p) => round.totalForPlayer(p.id) != 0)
        .toList();
    for (var i = 0; i < activePlayers.length; i++) {
      final p = activePlayers[i];
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
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Text.rich(TextSpan(children: spans, style: style));
  }
}
