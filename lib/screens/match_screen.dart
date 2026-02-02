import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/match_board_cubit.dart';
import '../cubit/match_board_state.dart';
import '../models/color.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../widgets/add_player_sheet.dart';
import '../widgets/options_sheet.dart';
import '../widgets/player_column.dart';
import '../widgets/round_history_sheet.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key, required this.onOpenHistory});

  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBoardCubit, MatchBoardState>(
      builder: (context, state) {
        final match = state.currentMatch!.ensureCurrentRound();
        return _MatchContent(match: match, onOpenHistory: onOpenHistory);
      },
    );
  }
}

class _MatchContent extends StatelessWidget {
  const _MatchContent({required this.match, required this.onOpenHistory});

  final MatchModel match;
  final VoidCallback onOpenHistory;

  void _update(BuildContext context, MatchModel updated) {
    context.read<MatchBoardCubit>().updateMatch(updated);
  }

  void _changeScore(BuildContext context, Player player, int delta) {
    final rounds = List<RoundModel>.from(match.rounds);
    RoundModel current;
    if (rounds.isEmpty) {
      current = RoundModel(index: 1, entries: []);
      rounds.add(current);
    } else {
      current = rounds.last;
    }

    final entries = List<RoundEntry>.from(current.entries);
    final idx = entries.indexWhere((e) => e.playerId == player.id);
    if (idx >= 0) {
      final existing = entries[idx];
      entries[idx] = RoundEntry(
        playerId: existing.playerId,
        delta: existing.delta + delta,
      );
    } else {
      entries.add(RoundEntry(playerId: player.id, delta: delta));
    }

    final updatedRound = RoundModel(index: current.index, entries: entries);
    rounds[rounds.length - 1] = updatedRound;

    _update(context, match.copyWith(rounds: rounds));
  }

  int _badgeDeltaFor(String playerId) {
    if (match.rounds.isEmpty) {
      return 0;
    }

    final RoundModel current = match.rounds.last;
    final bool currentHasChanges = current.entries.any((e) => e.delta != 0);

    if (currentHasChanges) {
      return current.totalForPlayer(playerId);
    }

    for (var i = match.rounds.length - 2; i >= 0; i--) {
      final round = match.rounds[i];
      final delta = round.totalForPlayer(playerId);
      if (delta != 0) {
        return delta;
      }
    }

    return 0;
  }

  void _resetMatch(BuildContext context) {
    _update(context, match.copyWith(rounds: []));
  }

  Future<void> _startNewMatch(BuildContext context) async {
    await context.read<MatchBoardCubit>().newMatch();
  }

  Future<void> _showRoundHistory(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => RoundHistorySheet(
        match: match,
        onNextRound: () {
          final nextIndex = match.rounds.isEmpty
              ? 1
              : match.rounds.last.index + 1;
          final newRound = RoundModel(index: nextIndex, entries: []);
          _update(context, match.copyWith(rounds: [...match.rounds, newRound]));
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Color _colorForIndex(int index) {
    if (kPlayerColors.isEmpty) {
      return Colors.grey;
    }
    return kPlayerColors[index % kPlayerColors.length];
  }

  void _openPlayerSheet(BuildContext context, {Player? player}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddPlayerSheet(
        match: match,
        player: player,
        colorForIndex: _colorForIndex,
        onSave: (updated) => _update(context, updated),
        onRemove: player != null
            ? (updated) => _update(context, updated)
            : null,
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => OptionsSheet(
        onResetMatch: () => _resetMatch(context),
        onNewMatch: () => _startNewMatch(context),
        onShowHistory: onOpenHistory,
      ),
    );
  }

  Widget _buildPlayerColumn(BuildContext context, Player player) {
    return PlayerColumn(
      player: player,
      score: match.scoreFor(player.id),
      lastDelta: _badgeDeltaFor(player.id),
      onTapPlus: () => _changeScore(context, player, 1),
      onSwipeDelta: (delta) => _changeScore(context, player, delta),
      onLongPress: () => _openPlayerSheet(context, player: player),
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = match.players;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: players.length <= 4
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final player in players)
                        Expanded(child: _buildPlayerColumn(context, player)),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final player in players.take(
                              (players.length) ~/ 2,
                            ))
                              Expanded(
                                child: _buildPlayerColumn(context, player),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final player in players.skip(
                              (players.length) ~/ 2,
                            ))
                              Expanded(
                                child: _buildPlayerColumn(context, player),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(child: _roundButton(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleIconButton(
                          icon: Icons.more_vert,
                          onTap: () => _showOptionsSheet(context),
                        ),
                        _circleIconButton(
                          icon: Icons.add,
                          onTap: () => _openPlayerSheet(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector _roundButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRoundHistory(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'ROUND ${match.rounds.isEmpty ? 1 : match.rounds.last.index}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const double size = 48;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
