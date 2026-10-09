import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player.dart';

class PlayerColumn extends StatefulWidget {
  const PlayerColumn({
    super.key,
    required this.player,
    required this.score,
    required this.lastDelta,
    this.scoreGroup,
    this.onTapPlus,
    this.onSwipeDelta,
    this.onLongPress,
    this.isRoundInvalid = false,
    this.locked = false,
  });

  final Player player;
  final int score;
  final int lastDelta;
  final AutoSizeGroup? scoreGroup;
  final VoidCallback? onTapPlus;
  final ValueChanged<int>? onSwipeDelta;
  final VoidCallback? onLongPress;
  final bool isRoundInvalid;
  final bool locked;

  @override
  State<PlayerColumn> createState() => _PlayerColumnState();
}

class _PlayerColumnState extends State<PlayerColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  bool _isScoreIncreasing = true;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flickerAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant PlayerColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != oldWidget.score) {
      _isScoreIncreasing = widget.score > oldWidget.score;
    }
    if (widget.isRoundInvalid && !_flickerController.isAnimating) {
      _flickerController.repeat(reverse: true);
    } else if (!widget.isRoundInvalid && _flickerController.isAnimating) {
      _flickerController.stop();
      _flickerController.reset();
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    super.dispose();
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _shiftHue(Color color, double degrees) {
    final hsl = HSLColor.fromColor(color);
    final newHue = (hsl.hue + degrees) % 360;
    return hsl.withHue(newHue).toColor();
  }

  void _handleTap() {
    final cb = widget.onTapPlus;
    if (cb == null) return;
    HapticFeedback.lightImpact();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.player.color;
    final fromColor = _lighten(baseColor, 0.15);
    final viaColor = _darken(baseColor, 0.1);
    final toColor = _shiftHue(baseColor, 30);

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [fromColor, viaColor, toColor],
      stops: const [0.0, 0.5, 1.0],
    );

    final lastDeltaText = widget.lastDelta == 0
        ? null
        : (widget.lastDelta > 0
              ? '+${widget.lastDelta}'
              : '${widget.lastDelta}');

    // When round is invalid, always show red; otherwise green/positive red/negative
    final badgeBorderColor = widget.isRoundInvalid
        ? Colors.red
        : (widget.lastDelta > 0 ? Colors.green : Colors.red).withValues(
            alpha: 0.7,
          );

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      onVerticalDragEnd: widget.onSwipeDelta == null
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < 0) {
                HapticFeedback.lightImpact();
                widget.onSwipeDelta!(1);
              } else if (velocity > 0) {
                HapticFeedback.mediumImpact();
                widget.onSwipeDelta!(-1);
              }
            },
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            // Score: center top portion, bounded so it never clips or overlaps bottom row
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              bottom: 48,
              child: ClipRect(
                child: Center(
                  child: AnimatedSwitcher(
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
                          scale: isCurrent
                              ? scale
                              : const AlwaysStoppedAnimation(1.0),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: AutoSizeText(
                      '${widget.score}',
                      key: ValueKey<int>(widget.score),
                      group: widget.scoreGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 140,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      minFontSize: 24,
                      maxFontSize: 140,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            // Bottom row: Name on bottom-left, Score changes on bottom-right
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AutoSizeText(
                      widget.player.name,
                      maxLines: 1,
                      minFontSize: 14,
                      maxFontSize: 28,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: lastDeltaText == null
                        ? const SizedBox.shrink(key: ValueKey('empty_delta'))
                        : Padding(
                            key: ValueKey<String>(lastDeltaText),
                            padding: const EdgeInsets.only(left: 8),
                            child: AnimatedBuilder(
                              animation: _flickerAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: widget.isRoundInvalid
                                      ? _flickerAnimation.value
                                      : 1.0,
                                  child: child,
                                );
                              },
                              child: Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: badgeBorderColor,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  lastDeltaText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
