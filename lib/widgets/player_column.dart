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
    this.onTapPlus,
    this.onSwipeDelta,
    this.onLongPress,
    this.isRoundInvalid = false,
    this.locked = false,
  });

  final Player player;
  final int score;
  final int lastDelta;
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
            Align(
              alignment: Alignment(0.0, 0.6),
              child: Transform.rotate(
                angle: -10 * (3.141592653589793 / 180), // 45 degrees in radians
                child: AutoSizeText(
                  widget.player.name,
                  maxLines: 1,
                  maxFontSize: 120,
                  minFontSize: 50,
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (lastDeltaText != null)
              Positioned(
                right: 8,
                bottom: 8,
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
                    height: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: badgeBorderColor),
                    ),
                    child: Text(
                      lastDeltaText,
                      style: const TextStyle(color: Colors.white, fontSize: 25),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: AutoSizeText(
                    '${widget.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 90,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    minFontSize: 24,
                    maxFontSize: 90,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
