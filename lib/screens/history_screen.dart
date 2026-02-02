import 'package:flutter/material.dart';
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
          return ListTile(
            title: Text(
              'Match: ${DateFormat('y d MMM - HH:mm').format(match.createdAt.toLocal())}',
              style: TextStyle(
                fontWeight:
                    isCurrent ? FontWeight.bold : null,
              ),
            ),
            subtitle: Text(_summaryForMatch(match)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop(match);
            },
          );
        },
      ),
    );
  }

  String _summaryForMatch(MatchModel match) {
    return match.players
        .map((p) => '${p.name}: ${match.scoreFor(p.id)}')
        .join('\n');
  }
}

