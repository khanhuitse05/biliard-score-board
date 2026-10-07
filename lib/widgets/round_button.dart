import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoundButton extends StatefulWidget {
  const RoundButton({
    super.key,
    required this.roundIndex,
    required this.onTap,
  });

  final int roundIndex;
  final VoidCallback onTap;

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flickerController;
  late final Animation<double> _flickerAnimation;

  int _lastRoundIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastRoundIndex = widget.roundIndex;

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant RoundButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Round index changed → new round was created, trigger flicker
    if (widget.roundIndex != _lastRoundIndex) {
      _lastRoundIndex = widget.roundIndex;
      _flickerController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
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
        animation: _flickerAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _flickerAnimation.value,
            child: child,
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
