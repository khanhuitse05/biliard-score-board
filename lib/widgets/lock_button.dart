import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LockButton extends StatefulWidget {
  const LockButton({
    super.key,
    required this.isLocked,
    required this.isCountingDown,
    required this.resetTrigger,
    required this.flickerTrigger,
    required this.onTap,
    required this.onCountdownComplete,
  });

  final bool isLocked;
  final bool isCountingDown;
  final int resetTrigger;
  final int flickerTrigger;
  final VoidCallback onTap;
  final VoidCallback onCountdownComplete;

  @override
  State<LockButton> createState() => _LockButtonState();
}

class _LockButtonState extends State<LockButton>
    with TickerProviderStateMixin {
  late final AnimationController _countdownController;
  late final Animation<double> _countdownAnimation;

  late final AnimationController _flickerController;
  late final Animation<double> _flickerAnimation;

  late final AnimationController _snapController;
  late final Animation<double> _snapAnimation;

  static const _countdownDuration = Duration(seconds: 5);
  int _lastResetTrigger = -1;
  int _lastFlickerTrigger = 0;
  bool _lastIsCountingDown = false;

  @override
  void initState() {
    super.initState();
    _lastResetTrigger = widget.resetTrigger;
    _lastFlickerTrigger = widget.flickerTrigger;
    _lastIsCountingDown = widget.isCountingDown;

    _countdownController = AnimationController(
      vsync: this,
      duration: _countdownDuration,
    );
    _countdownAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );

    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onComplete();
      }
    });

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _snapAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );

    if (widget.isCountingDown) {
      _countdownController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LockButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.flickerTrigger != _lastFlickerTrigger) {
      _lastFlickerTrigger = widget.flickerTrigger;
      _flickerController.forward(from: 0.0);
    }

    if (widget.resetTrigger != _lastResetTrigger) {
      _lastResetTrigger = widget.resetTrigger;
      _countdownController.reset();
      if (widget.isCountingDown) {
        _countdownController.forward();
      }
    }

    if (widget.isCountingDown != _lastIsCountingDown) {
      _lastIsCountingDown = widget.isCountingDown;
      if (widget.isCountingDown) {
        _countdownController.reset();
        _countdownController.forward();
      } else {
        _countdownController.stop();
        _countdownController.reset();
      }
    }
  }

  void _onComplete() {
    _snapController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
    widget.onCountdownComplete();
  }

  void _handleTap() {
    if (widget.isCountingDown) {
      // Immediately finish countdown & lock without waiting
      _countdownController.stop();
      _countdownController.value = 1.0;
      _onComplete();
    } else {
      HapticFeedback.selectionClick();
      widget.onTap();
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _flickerController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 50;
    const progressColor = Color(0xFF00E5FF); // Neon cyan progress ring

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _countdownAnimation,
          _flickerAnimation,
          _snapAnimation,
        ]),
        builder: (context, child) {
          final scale = _flickerController.isAnimating
              ? _flickerAnimation.value
              : (_snapController.isAnimating ? _snapAnimation.value : 1.0);

          return Transform.scale(
            scale: scale,
            child: CustomPaint(
              painter: _CircularCountdownPainter(
                progress: widget.isCountingDown ? _countdownAnimation.value : 0.0,
                color: progressColor,
              ),
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: widget.isLocked
                ? Colors.red.withValues(alpha: 0.3)
                : (widget.isCountingDown
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.12)),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isLocked
                  ? Colors.red.withValues(alpha: 0.7)
                  : (widget.isCountingDown
                      ? progressColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.4)),
              width: widget.isLocked ? 2.5 : 1.5,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _countdownAnimation,
              builder: (context, _) {
                if (widget.isCountingDown) {
                  final remaining = (5 * (1.0 - _countdownAnimation.value))
                      .ceil()
                      .clamp(1, 5);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      '$remaining',
                      key: ValueKey<int>(remaining),
                      style: const TextStyle(
                        color: progressColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  );
                }

                return Icon(
                  widget.isLocked ? Icons.lock : Icons.lock_open,
                  key: ValueKey<bool>(widget.isLocked),
                  color: Colors.white,
                  size: 24,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularCountdownPainter extends CustomPainter {
  _CircularCountdownPainter({
    required this.progress,
    required this.color,
  });

  static const double strokeWidth = 3.0;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Faint track background for reference
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc starting from 12 o'clock (-pi / 2) sweeping clockwise
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularCountdownPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
