import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/match_board_cubit.dart';
import '../cubit/match_board_state.dart';
import '../models/color.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../widgets/add_player_sheet.dart';
import '../widgets/lock_toast.dart';
import '../widgets/options_sheet.dart';
import '../widgets/player_column.dart';
import '../widgets/reset_match_dialog.dart';
import '../widgets/round_button.dart';
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

class _MatchContent extends StatefulWidget {
  const _MatchContent({required this.match, required this.onOpenHistory});

  final MatchModel match;
  final VoidCallback onOpenHistory;

  @override
  State<_MatchContent> createState() => _MatchContentState();
}

class _MatchContentState extends State<_MatchContent> {
  /// Incremented on every score change to signal RoundButton to restart its
  /// countdown animation.
  int _countdownResetTrigger = 0;

  /// When true, all score editing and player management is disabled.
  bool _isLocked = false;

  MatchModel get match => widget.match;

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
  }

  void _update(BuildContext context, MatchModel updated) {
    context.read<MatchBoardCubit>().updateMatch(updated);
  }

  void _changeScore(BuildContext context, Player player, int delta) {
    if (_isLocked) {
      showLockToast(context);
      return;
    }
    final rounds = List<RoundModel>.from(match.rounds);
    RoundModel current;
    if (rounds.isEmpty) {
      current = RoundModel(index: 1, entries: [], createdAt: DateTime.now());
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

    final updatedRound = RoundModel(
      index: current.index,
      entries: entries,
      createdAt: current.createdAt,
    );
    rounds[rounds.length - 1] = updatedRound;

    _update(context, match.copyWith(rounds: rounds));

    // Signal RoundButton that a score changed
    _countdownResetTrigger++;
  }

  void _onCountdownComplete() {
    if (!mounted) return;

    final currentMatch = context.read<MatchBoardCubit>().state.currentMatch;
    if (currentMatch == null) return;

    final rounds = currentMatch.rounds;
    if (rounds.isEmpty) return;

    final lastRound = rounds.last;
    final roundTotal = lastRound.roundTotal;

    // Only auto-advance if round total is 0 (valid round)
    if (roundTotal != 0) return;

    // Only advance if at least one player had a non-zero delta
    final somePlayerScored = currentMatch.players.any(
      (p) => lastRound.totalForPlayer(p.id) != 0,
    );
    if (!somePlayerScored) return;

    final nextIndex = lastRound.index + 1;
    final newRound = RoundModel(
      index: nextIndex,
      entries: [],
      createdAt: DateTime.now(),
    );
    _update(context, currentMatch.copyWith(rounds: [...rounds, newRound]));

    // Auto-lock after round auto-advances
    setState(() {
      _isLocked = true;
    });
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

  /// Returns true when the current round's total is non-zero, meaning the
  /// scores are invalid and the lastDelta badge should turn red and flicker.
  bool get _isRoundInvalid {
    if (match.rounds.isEmpty) return false;
    final total = match.rounds.last.roundTotal;
    final hasChanges = match.rounds.last.entries.any((e) => e.delta != 0);
    return hasChanges && total != 0;
  }

  int get _currentRoundIndex =>
      match.rounds.isEmpty ? 1 : match.rounds.last.index;

  Future<void> _resetMatch(BuildContext context) async {
    final confirmed = await ResetMatchDialog.show(context);

    if (confirmed == true && context.mounted) {
      _countdownResetTrigger++;
      _update(context, match.copyWith(rounds: []));
    }
  }

  Future<void> _startNewMatch(BuildContext context) async {
    await context.read<MatchBoardCubit>().newMatch();
  }

  Future<void> _showRoundHistory(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => RoundHistorySheet(match: match),
    );
  }

  Color _colorForIndex(int index) {
    if (kPlayerColors.isEmpty) {
      return Colors.grey;
    }
    return kPlayerColors[index % kPlayerColors.length];
  }

  void _openPlayerSheet(BuildContext context, {Player? player}) {
    if (_isLocked && player != null) {
      showLockToast(context);
      return;
    }
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
      isScrollControlled: true,
      builder: (ctx) => OptionsSheet(
        onAddPlayer: () => _openPlayerSheet(context),
        onResetMatch: () => _resetMatch(context),
        onNewMatch: () => _startNewMatch(context),
        onShowHistory: widget.onOpenHistory,
      ),
    );
  }

  Widget _buildPlayerColumn(BuildContext context, Player player) {
    return PlayerColumn(
      player: player,
      score: match.scoreFor(player.id),
      lastDelta: _badgeDeltaFor(player.id),
      isRoundInvalid: _isRoundInvalid,
      locked: _isLocked,
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
            child: players.length < 4
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RoundButton(
                          roundIndex: _currentRoundIndex,
                          resetTrigger: _countdownResetTrigger,
                          isRoundValid: !_isRoundInvalid,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showRoundHistory(context);
                          },
                          onCountdownComplete: _onCountdownComplete,
                        ),
                        _lockButton(),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleIconButton(
                          icon: Icons.more_vert,
                          onTap: () => _showOptionsSheet(context),
                        ),
                        // _circleIconButton(
                        //   icon: Icons.add,
                        //   onTap: () => _openPlayerSheet(context),
                        // ),
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

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const double size = 48;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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

  Widget _lockButton() {
    const double size = 48;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _toggleLock();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _isLocked
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isLocked
                ? Colors.red.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.4),
            width: _isLocked ? 2.5 : 1,
          ),
        ),
        child: Icon(
          _isLocked ? Icons.lock : Icons.lock_open,
          color: _isLocked ? Colors.red : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}