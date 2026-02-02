import 'package:flutter/material.dart';

import 'color.dart';
import 'player.dart';
import 'round.dart';

class MatchModel {
  MatchModel({
    required this.id,
    required this.createdAt,
    required this.players,
    required this.rounds,
  });

  final String id;
  final DateTime createdAt;
  final List<Player> players;
  final List<RoundModel> rounds;

  factory MatchModel.createDefault() {
    final now = DateTime.now();
    return MatchModel(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      players: [
        Player(
          id: 'p1',
          name: 'Player 1',
          color: kPlayerColors.isNotEmpty
              ? kPlayerColors[0]
              : const Color(0xFF9C27B0),
        ),
        Player(
          id: 'p2',
          name: 'Player 2',
          color: kPlayerColors.length > 1
              ? kPlayerColors[1]
              : const Color(0xFF2196F3),
        ),
      ],
      rounds: [],
    );
  }

  MatchModel copyWith({
    String? id,
    DateTime? createdAt,
    List<Player>? players,
    List<RoundModel>? rounds,
  }) {
    return MatchModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'players': players.map((p) => p.toJson()).toList(growable: false),
      'rounds': rounds.map((r) => r.toJson()).toList(growable: false),
    };
  }

  static MatchModel fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      rounds: (json['rounds'] as List<dynamic>)
          .map((e) => RoundModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int scoreFor(String playerId) {
    return rounds.fold<int>(
      0,
      (sum, r) => sum + r.totalForPlayer(playerId),
    );
  }

  int lastDeltaFor(String playerId) {
    for (var i = rounds.length - 1; i >= 0; i--) {
      final round = rounds[i];
      for (final entry in round.entries) {
        if (entry.playerId == playerId) {
          return entry.delta;
        }
      }
    }
    return 0;
  }

  RoundModel? get currentRound =>
      rounds.isEmpty ? null : rounds.last;

  MatchModel ensureCurrentRound() {
    if (currentRound != null) return this;
    final newRound = RoundModel(index: 1, entries: []);
    return copyWith(rounds: [...rounds, newRound]);
  }
}

