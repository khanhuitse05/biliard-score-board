import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RaceTargetDialog extends StatefulWidget {
  const RaceTargetDialog({
    super.key,
    required this.currentTarget,
    required this.onTargetChanged,
  });

  final int currentTarget;
  final ValueChanged<int> onTargetChanged;

  static Future<void> show(
    BuildContext context, {
    required int currentTarget,
    required ValueChanged<int> onTargetChanged,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => RaceTargetDialog(
        currentTarget: currentTarget,
        onTargetChanged: onTargetChanged,
      ),
    );
  }

  @override
  State<RaceTargetDialog> createState() => _RaceTargetDialogState();
}

class _RaceTargetDialogState extends State<RaceTargetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentTarget}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final current = int.tryParse(_controller.text) ?? widget.currentTarget;
    final next = (current + delta).clamp(1, 99);
    HapticFeedback.selectionClick();
    _controller.text = '$next';
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text);
    final target = (parsed ?? widget.currentTarget).clamp(1, 99);
    HapticFeedback.selectionClick();
    widget.onTargetChanged(target);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF130E2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFF00E5FF),
          width: 1.5,
        ),
      ),
      title: const Text(
        'Race Target',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Color(0xFF00E5FF),
              size: 30,
            ),
            onPressed: () => _step(-1),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF00E5FF),
                    width: 2,
                  ),
                ),
              ),
              onTap: () {
                _controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controller.text.length,
                );
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF00E5FF),
              size: 30,
            ),
            onPressed: () => _step(1),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: const Color(0xFF0C091A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _submit,
          child: const Text(
            'Done',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
