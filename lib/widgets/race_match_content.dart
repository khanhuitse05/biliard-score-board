import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/match_board_cubit.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/round.dart';
import 'add_player_sheet.dart';
import 'lock_button.dart';
import 'lock_toast.dart';
import 'options_sheet.dart';
import 'race_target_dialog.dart';

class RaceMatchContent extends StatefulWidget {
  const RaceMatchContent({
    super.key,
    required this.match,
    required this.onOpenHistory,
  });

  final MatchModel match;
  final VoidCallback onOpenHistory;

  @override
  State<RaceMatchContent> createState() => _RaceMatchContentState();
}

class _RaceMatchContentState extends State<RaceMatchContent> {

  bool _isLocked = false;
  bool _isCountingDown = false;
  int _countdownResetTrigger = 0;
  int _lockFlickerTrigger = 0;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  MatchModel get match => widget.match;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateElapsed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    setState(() {
      final endTime = match.effectiveEndTime;
      if (endTime != null) {
        _elapsed = endTime.difference(match.createdAt);
      } else {
        _elapsed = DateTime.now().difference(match.createdAt);
      }
      if (_elapsed.isNegative) _elapsed = Duration.zero;
    });
  }

  String get _formattedTime {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (_elapsed.inHours > 0) {
      final hours = _elapsed.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void didUpdateWidget(covariant RaceMatchContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.match.id != oldWidget.match.id ||
        widget.match.endedAt != oldWidget.match.endedAt ||
        widget.match.rounds.length != oldWidget.match.rounds.length) {
      _updateElapsed();
    }
    if (widget.match.id != oldWidget.match.id) {
      _isLocked = false;
      _isCountingDown = false;
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _isCountingDown = false;
      }
    });
  }

  void _triggerLockFlicker() {
    if (_isLocked) {
      setState(() {
        _lockFlickerTrigger++;
      });
    }
  }

  void _onCountdownComplete() {
    if (!mounted) return;
    setState(() {
      _isLocked = true;
      _isCountingDown = false;
    });
  }

  void _update(BuildContext context, MatchModel updated) {
    context.read<MatchBoardCubit>().updateMatch(updated);
  }

  void _onPlayerTap(BuildContext context, Player player) {
    if (_isLocked) {
      showToast(context, 'Screen locked');
      _triggerLockFlicker();
      return;
    }

    final winner = match.raceWinner;
    if (winner != null) {
      return;
    }

    final nextIndex = match.rounds.length + 1;
    final now = DateTime.now();
    final newRound = RoundModel(
      index: nextIndex,
      entries: [RoundEntry(playerId: player.id, delta: 1)],
      createdAt: now,
    );

    final updatedMatch = match.copyWith(
      rounds: [...match.rounds, newRound],
    );

    final newScore = updatedMatch.scoreFor(player.id);
    final hasWon = newScore >= updatedMatch.raceTarget;

    final finalMatch = hasWon
        ? updatedMatch.copyWith(endedAt: now)
        : updatedMatch;

    _update(context, finalMatch);

    if (hasWon) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _countdownResetTrigger++;
      _isCountingDown = !hasWon;
    });
  }

  void _onPlayerSwipeDown(BuildContext context, Player player) {
    if (_isLocked) {
      showToast(context, 'Screen locked');
      _triggerLockFlicker();
      return;
    }

    final currentScore = match.scoreFor(player.id);
    if (currentScore <= 0) return;

    HapticFeedback.mediumImpact();

    final rounds = List<RoundModel>.from(match.rounds);
    final lastWonIndex = rounds.lastIndexWhere(
      (r) => r.entries.any((e) => e.playerId == player.id && e.delta > 0),
    );

    if (lastWonIndex >= 0) {
      rounds.removeAt(lastWonIndex);
      final reindexed = [
        for (var i = 0; i < rounds.length; i++)
          RoundModel(
            index: i + 1,
            entries: rounds[i].entries,
            createdAt: rounds[i].createdAt,
          )
      ];
      final updatedMatch = match.copyWith(
        rounds: reindexed,
        clearEndedAt: true,
      );

      final hasWinner = updatedMatch.raceWinner != null;
      final finalMatch = hasWinner
          ? updatedMatch.copyWith(endedAt: match.endedAt ?? DateTime.now())
          : updatedMatch;
      _update(context, finalMatch);

      setState(() {
        _countdownResetTrigger++;
        _isCountingDown = !hasWinner;
      });
    }
  }

  void _rematch(BuildContext context) {
    _isLocked = false;
    _isCountingDown = false;
    _countdownResetTrigger++;
    _update(
      context,
      match.copyWith(
        rounds: [],
        createdAt: DateTime.now(),
        clearEndedAt: true,
      ),
    );
  }

  void _startNewRace(BuildContext context) {
    _isLocked = false;
    _isCountingDown = false;
    _countdownResetTrigger++;
    context.read<MatchBoardCubit>().newRaceMatch(raceTarget: match.raceTarget);
  }

  void _openTargetDialog(BuildContext context) {
    if (_isLocked) {
      showToast(context, 'Screen locked');
      _triggerLockFlicker();
      return;
    }
    RaceTargetDialog.show(
      context,
      currentTarget: match.raceTarget,
      onTargetChanged: (newTarget) {
        final updated = match.copyWith(raceTarget: newTarget);
        final hasWinner = updated.raceWinner != null;
        final finalMatch = hasWinner
            ? (updated.endedAt != null ? updated : updated.copyWith(endedAt: DateTime.now()))
            : updated.copyWith(clearEndedAt: true);
        _update(context, finalMatch);
      },
    );
  }

  void _openPlayerSheet(BuildContext context, Player player) {
    if (_isLocked) {
      showToast(context, 'Screen locked');
      _triggerLockFlicker();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddPlayerSheet(
        match: match,
        player: player,
        colorForIndex: (_) => player.color,
        onSave: (updated) => _update(context, updated),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => OptionsSheet(
        isRaceMode: true,
        onAddPlayer: () {},
        onResetMatch: () => _rematch(context),
        onNewMatch: () => context.read<MatchBoardCubit>().newMatch(),
        onNewRace: () => _startNewRace(context),
        onShowHistory: widget.onOpenHistory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = match.players;
    final player1 = players.isNotEmpty ? players[0] : null;
    final player2 = players.length > 1 ? players[1] : null;

    if (player1 == null || player2 == null) {
      return const Scaffold(
        body: Center(child: Text('2 players required for Race to N')),
      );
    }

    final p1Score = match.scoreFor(player1.id);
    final p2Score = match.scoreFor(player2.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1C),
      body: Stack(
        children: [
          // Retro 8-Bit Arcade CRT Grid Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcadeGridPainter(
                p1Color: player1.color,
                p2Color: player2.color,
              ),
            ),
          ),

          // Main 2-Player Head-to-Head Content
          Positioned.fill(
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Player 1 Side (Left)
                  Expanded(
                    child: _buildPlayerHalf(
                      context,
                      player: player1,
                      score: p1Score,
                    ),
                  ),

                  // Center Win Streak Dot Matrix Logger
                  _buildCenterDotLog(player1, player2),

                  // Player 2 Side (Right)
                  Expanded(
                    child: _buildPlayerHalf(
                      context,
                      player: player2,
                      score: p2Score,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Circle Option Button
                    _buildCircleOptionButton(),

                    // Center Match Clock & "Race to N" Label
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Elapsed Time
                        Text(
                          _formattedTime,
                          style: TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Race to N Target Label
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _openTargetDialog(context);
                          },
                          child: Text(
                            'Race to ${match.raceTarget}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Right Lock Button
                    LockButton(
                      isLocked: _isLocked,
                      isCountingDown: _isCountingDown,
                      resetTrigger: _countdownResetTrigger,
                      flickerTrigger: _lockFlickerTrigger,
                      onTap: _toggleLock,
                      onCountdownComplete: _onCountdownComplete,
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

  Widget _buildCircleOptionButton() {
    const double size = 50;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showOptionsSheet(context);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.more_vert,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPlayerHalf(
    BuildContext context, {
    required Player player,
    required int score,
  }) {
    final isWinner = match.raceWinner?.id == player.id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onPlayerTap(context, player),
      onSecondaryTap: () => _onPlayerSwipeDown(context, player),
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0) {
          _onPlayerSwipeDown(context, player);
        } else if (velocity < 0) {
          _onPlayerTap(context, player);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            const SizedBox(height: 72),
            // Big 8-Bit Pixel Digit (dynamically scales to fill available space)
            Expanded(
              child: ClipRect(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _ArcadeScoreDisplay(
                      score: score,
                      color: player.color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: isWinner
                  ? Padding(
                      key: const ValueKey('victory_badge'),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildVictoryBadge(player),
                    )
                  : const SizedBox.shrink(key: ValueKey('no_badge')),
            ),
            // Player Name at bottom
            GestureDetector(
              onLongPress: () => _openPlayerSheet(context, player),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: player.color,
                      fontSize: 32,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: player.color.withValues(alpha: 0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryBadge(Player player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: player.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: player.color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: player.color.withValues(alpha: 0.55),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: player.color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'VICTORY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  color: player.color.withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterDotLog(Player p1, Player p2) {
    final totalDots = match.raceTarget;
    final rounds = match.rounds;

    // Determine number of columns so dots form a neat 8-bit matrix
    final int columns;
    if (totalDots <= 10) {
      columns = 2;
    } else if (totalDots <= 18) {
      columns = 3;
    } else {
      columns = 4;
    }

    final int rowsPerColumn = (totalDots / columns).ceil();
    final double dotSize = totalDots > 20 ? 11.0 : 13.0;
    final double spacing = totalDots > 20 ? 4.0 : 5.0;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(columns, (colIdx) {
            final startIdx = colIdx * rowsPerColumn;
            final endIdx = (startIdx + rowsPerColumn).clamp(0, totalDots);
            final countInCol = (endIdx - startIdx).clamp(0, rowsPerColumn);

            if (countInCol <= 0) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(countInCol, (rowIdx) {
                  // Column-major indexing: rack 1 is col 1 row 1, rack 2 is col 1 row 2, etc.
                  final index = startIdx + rowIdx;
                  Color dotColor;
                  bool isFilled = false;

                  if (index < rounds.length) {
                    final round = rounds[index];
                    final isP1 = round.entries.any((e) => e.playerId == p1.id && e.delta > 0);
                    final isP2 = round.entries.any((e) => e.playerId == p2.id && e.delta > 0);

                    if (isP1) {
                      dotColor = p1.color; // Cyan
                      isFilled = true;
                    } else if (isP2) {
                      dotColor = p2.color; // Pink
                      isFilled = true;
                    } else {
                      dotColor = const Color(0xFFFFD54F); // Yellow
                      isFilled = true;
                    }
                  } else {
                    dotColor = const Color(0xFF221A3D); // Unearned dim dot
                    isFilled = false;
                  }

                  final dotWidget = Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: isFilled ? dotColor : const Color(0xFF16102D),
                      borderRadius: BorderRadius.circular(2.5),
                      border: Border.all(
                        color: isFilled
                            ? dotColor
                            : const Color(0xFF2E2452),
                        width: 1.0,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: dotColor.withValues(alpha: 0.85),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : null,
                    ),
                  );

                  if (rowIdx < countInCol - 1) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: dotWidget,
                    );
                  }
                  return dotWidget;
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ArcadeGridPainter extends CustomPainter {
  const _ArcadeGridPainter({
    required this.p1Color,
    required this.p2Color,
  });

  final Color p1Color;
  final Color p2Color;

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    final bgPaint = Paint()..color = const Color(0xFF0C091A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle CRT Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E1738)
      ..strokeWidth = 1.0;

    const double cellSize = 22.0;

    for (double x = 0; x < size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Left ambient cyan glow
    final p1Glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.2),
        radius: 0.8,
        colors: [
          p1Color.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.55, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.55, size.height), p1Glow);

    // Right ambient pink glow
    final p2Glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.6, 0.2),
        radius: 0.8,
        colors: [
          p2Color.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.45, 0, size.width * 0.55, size.height));
    canvas.drawRect(Rect.fromLTWH(size.width * 0.45, 0, size.width * 0.55, size.height), p2Glow);
  }

  @override
  bool shouldRepaint(covariant _ArcadeGridPainter oldDelegate) {
    return oldDelegate.p1Color != p1Color || oldDelegate.p2Color != p2Color;
  }
}

class _ArcadeScoreDisplay extends StatefulWidget {
  const _ArcadeScoreDisplay({
    required this.score,
    required this.color,
  });

  final int score;
  final Color color;

  @override
  State<_ArcadeScoreDisplay> createState() => _ArcadeScoreDisplayState();
}

class _ArcadeScoreDisplayState extends State<_ArcadeScoreDisplay> {
  bool _isScoreIncreasing = true;

  @override
  void didUpdateWidget(covariant _ArcadeScoreDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != oldWidget.score) {
      _isScoreIncreasing = widget.score > oldWidget.score;
    }
  }

  Widget _build8BitScore(int score, Color color) {
    return Stack(
      key: ValueKey<int>(score),
      alignment: Alignment.center,
      children: [
        // Ambient Neon Glow behind number
        Text(
          '$score',
          style: TextStyle(
            fontSize: 260,
            color: color.withValues(alpha: 0.3),
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.7),
                blurRadius: 18,
              ),
            ],
          ),
        ),
        // Sharp, distinct foreground number
        Text(
          '$score',
          style: TextStyle(
            fontSize: 260,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        final isCurrent = child.key is ValueKey<int> &&
            (child.key as ValueKey<int>).value == widget.score;

        final inOffset = Tween<Offset>(
          begin: Offset(0.0, _isScoreIncreasing ? 0.6 : -0.6),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        final outOffset = Tween<Offset>(
          begin: Offset(0.0, _isScoreIncreasing ? -0.6 : 0.6),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInCubic,
        ));

        final scale = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

        return SlideTransition(
          position: isCurrent ? inOffset : outOffset,
          child: ScaleTransition(
            scale: isCurrent ? scale : const AlwaysStoppedAnimation(1.0),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: _build8BitScore(widget.score, widget.color),
    );
  }
}

