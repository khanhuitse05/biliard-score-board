import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/match.dart';
import '../models/player.dart';

/// Default names the user can quick-select when adding/editing a player.
const defaultPlayerNames = ['Khá', 'Damy', 'Bino', 'Lú', 'PKon', 'James', 'Gãy'];

class AddPlayerSheet extends StatefulWidget {
  const AddPlayerSheet({
    super.key,
    required this.match,
    this.player,
    required this.colorForIndex,
    required this.onSave,
    this.onRemove,
  });

  final MatchModel match;
  final Player? player;
  final Color Function(int index) colorForIndex;
  final void Function(MatchModel updated) onSave;
  final void Function(MatchModel updated)? onRemove;

  @override
  State<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<AddPlayerSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.player != null;

  void _submit() {
    final name = _nameController.text.trim().isEmpty
        ? 'Player ${widget.match.players.length + 1}'
        : _nameController.text.trim();

    if (_isEdit) {
      final updatedPlayers = widget.match.players
          .map(
            (p) => p.id == widget.player!.id
                ? p.copyWith(name: name)
                : p,
          )
          .toList();
      widget.onSave(widget.match.copyWith(players: updatedPlayers));
    } else {
      final newPlayer = Player(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        color: widget.colorForIndex(widget.match.players.length),
      );
      final updatedPlayers = [...widget.match.players, newPlayer];
      widget.onSave(widget.match.copyWith(players: updatedPlayers));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            _isEdit ? 'Edit player' : 'Add player',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            // autofocus: !_isEdit,
          ),
          const SizedBox(height: 16),
          Text(
            'Quick select:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: defaultPlayerNames.map((name) {
              // Check if this name is already used by another player
              final isNameTaken = widget.match.players.any(
                (p) => p.name == name && (_isEdit ? p.id != widget.player!.id : true),
              );
              return ActionChip(
                label: Text(name),
                onPressed: isNameTaken
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        _nameController.text = name;
                        _submit();
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isEdit && widget.onRemove != null)
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final updated = widget.match.copyWith(
                      players: List.from(widget.match.players)
                        ..removeWhere((p) => p.id == widget.player!.id),
                    );
                    widget.onRemove!(updated);
                    if (mounted) Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Remove'),
                )
              else
                const SizedBox.shrink(),
              Row(
                spacing: 16,
                children: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _submit();
                    },
                    child: Text(_isEdit ? 'Save' : 'Add'),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
