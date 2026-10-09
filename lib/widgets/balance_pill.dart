import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BalancePill extends StatefulWidget {
  const BalancePill({
    super.key,
    required this.roundTotal,
    required this.hasChanges,
    required this.isCountingDown,
    this.onTap,
  });

  final int roundTotal;
  final bool hasChanges;
  final bool isCountingDown;
  final VoidCallback? onTap;

  @override
  State<BalancePill> createState() => _BalancePillState();
}

class _BalancePillState extends State<BalancePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.hasChanges && widget.roundTotal != 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BalancePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isInvalid = widget.hasChanges && widget.roundTotal != 0;
    if (isInvalid && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isInvalid && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = widget.hasChanges;
    final roundTotal = widget.roundTotal;
    final isInvalid = hasChanges && roundTotal != 0;
    final isBalanced = hasChanges && roundTotal == 0;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (isInvalid) {
      final diffSign = roundTotal > 0 ? '+$roundTotal' : '$roundTotal';
      bgColor = Colors.red.withValues(alpha: 0.28);
      borderColor = Colors.redAccent.withValues(alpha: 0.85);
      textColor = const Color(0xFFFF5252);
      icon = Icons.error_outline_rounded;
      label = 'DIFF: $diffSign';
    } else if (isBalanced) {
      bgColor = const Color(0xFF00E5FF).withValues(alpha: 0.18);
      borderColor = const Color(0xFF00E5FF).withValues(alpha: 0.75);
      textColor = const Color(0xFF00E5FF);
      icon = Icons.check_circle_outline_rounded;
      label = 'BALANCED ✓';
    } else {
      bgColor = Colors.white.withValues(alpha: 0.10);
      borderColor = Colors.white.withValues(alpha: 0.20);
      textColor = Colors.white.withValues(alpha: 0.70);
      icon = Icons.balance_rounded;
      label = '';
    }

    return GestureDetector(
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isInvalid ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isInvalid ? 1.5 : 1.0,
            ),
            boxShadow: isInvalid
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : (isBalanced
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  label,
                  key: ValueKey<String>(label),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
