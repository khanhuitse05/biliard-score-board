import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoundButton extends StatefulWidget {
  const RoundButton({
    super.key,
    required this.roundIndex,
    required this.onTap,
    required this.onCountdownComplete,
    required this.resetTrigger,
    required this.isRoundValid,
  });

  final int roundIndex;
  final VoidCallback onTap;
  final VoidCallback onCountdownComplete;

  /// Increment this value to restart the countdown animation.
  final int resetTrigger;

  /// When true the round scores are balanced (total == 0) and the countdown
  /// should run.  When false the countdown is stopped.
  final bool isRoundValid;

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late Animation<double> _countdownAnimation;
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  int _lastRoundIndex = 0;
  int _lastResetTrigger = -1;
  bool _lastIsRoundValid = false;

  static const _countdownDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _lastRoundIndex = widget.roundIndex;
    _lastResetTrigger = widget.resetTrigger;
    _lastIsRoundValid = widget.isRoundValid;

    _countdownController = AnimationController(
      vsync: this,
      duration: _countdownDuration,
    );
    _countdownAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flickerAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.9), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.08), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
        );

    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCountdownComplete();
      }
    });
  }

  @override
  void didUpdateWidget(covariant RoundButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Round index changed → new round was created, trigger flicker
    if (widget.roundIndex != _lastRoundIndex) {
      _lastRoundIndex = widget.roundIndex;
      _flickerController.forward(from: 0.0);
    }

    // Reset trigger changed → a score was changed
    if (widget.resetTrigger != _lastResetTrigger) {
      _lastResetTrigger = widget.resetTrigger;
      _countdownController.reset();
      if (widget.isRoundValid) {
        _countdownController.forward();
      }
    }

    // isRoundValid changed
    if (widget.isRoundValid != _lastIsRoundValid) {
      _lastIsRoundValid = widget.isRoundValid;
      if (widget.isRoundValid) {
        // Round became valid → restart countdown
        _countdownController.reset();
        _countdownController.forward();
      } else {
        // Round became invalid → stop countdown
        _countdownController.stop();
      }
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_countdownAnimation, _flickerAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _flickerAnimation.value,
            child: CustomPaint(
              painter: _CountdownBorderPainter(
                progress: _countdownAnimation.value,
                color: Colors.red.withValues(alpha: 0.7),
              ),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'LOG ${widget.roundIndex}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownBorderPainter extends CustomPainter {
  _CountdownBorderPainter({required this.progress, required this.color});

  final double progress; // 0.0 → 1.0
  final Color color;

  static const _radius = Radius.circular(32);
  static const _strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _radius,
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      final totalLen = metric.length;
      if (totalLen <= 0) continue;

      // Compute fraction along the perimeter that corresponds to top‑center.
      // An RRect path starts at the left‑side anchor of the top‑left rounded
      // corner and runs clockwise.
      final w = size.width;
      final h = size.height;
      final r = _radius.x.clamp(0.0, w / 2).clamp(0.0, h / 2);
      final flatTop = (w - 2 * r).clamp(0.0, double.infinity);
      final arcLen = (pi / 2) * r; // length of one quarter-circle arc

      // Distance from path start to top‑center:
      // arc‑top‑left (full) + half of flat top edge
      final toTopCenter = arcLen + flatTop / 2;
      final startFrac = (toTopCenter / totalLen).clamp(0.0, 1.0);

      final endFrac = startFrac + progress;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      if (endFrac <= 1.0) {
        // Single continuous segment
        final extractedPath = metric.extractPath(
          startFrac * totalLen,
          endFrac * totalLen,
        );
        canvas.drawPath(extractedPath, paint);
      } else {
        // Wrap around the end of the closed loop
        final extractedPath1 = metric.extractPath(
          startFrac * totalLen,
          totalLen,
        );
        canvas.drawPath(extractedPath1, paint);

        final extractedPath2 = metric.extractPath(
          0,
          (endFrac - 1.0) * totalLen,
        );
        canvas.drawPath(extractedPath2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
