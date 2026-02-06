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
    required this.onTapPlus,
    required this.onSwipeDelta,
    required this.onLongPress,
  });

  final Player player;
  final int score;
  final int lastDelta;
  final VoidCallback onTapPlus;
  final ValueChanged<int> onSwipeDelta;
  final VoidCallback onLongPress;

  @override
  State<PlayerColumn> createState() => _PlayerColumnState();
}

class _PlayerColumnState extends State<PlayerColumn> {

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
    // Trigger haptics immediately
    HapticFeedback.lightImpact();
    
    // Trigger score change
    widget.onTapPlus();
  }

  @override
  Widget build(BuildContext context) {
    // Create gradient similar to Tailwind: from-500 via-600 to-complementary
    final baseColor = widget.player.color;
    final fromColor = _lighten(baseColor, 0.15); // Lighter start (like -500)
    final viaColor = _darken(baseColor, 0.1); // Darker middle (like -600)
    final toColor = _shiftHue(baseColor, 30); // Shift hue for complementary end

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [fromColor, viaColor, toColor],
      stops: const [0.0, 0.5, 1.0],
    );

    final lastDeltaText = widget.lastDelta == 0
        ? null
        : (widget.lastDelta > 0 ? '+${widget.lastDelta}' : '${widget.lastDelta}');

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0) {
          // Swipe up - increase score
          HapticFeedback.lightImpact();
          widget.onSwipeDelta(1);
        } else if (velocity > 0) {
          // Swipe down - decrease score
          HapticFeedback.mediumImpact();
          widget.onSwipeDelta(-1);
        }
      },
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.player.name,
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 28),
            ),
            Container(
              alignment: Alignment.center,
              child: AutoSizeText(
                '${widget.score}',
                style: const TextStyle(color: Colors.white, fontSize: 70),
                maxLines: 1,
                minFontSize: 24,
                maxFontSize: 70,
                textAlign: TextAlign.center,
              ),
            ),
            if (lastDeltaText != null)
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (widget.lastDelta > 0 ? Colors.green : Colors.red).withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  lastDeltaText,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
