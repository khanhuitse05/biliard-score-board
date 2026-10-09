import 'package:flutter/material.dart';

import 'color.dart';
import 'player.dart';
import 'round.dart';

enum GameMode {
  zeroSum,
  raceToRacks;

  String get displayName {
    switch (this) {
      case GameMode.zeroSum:
        return 'Đánh Đền';
      case GameMode.raceToRacks:
        return 'Race to Racks';
    }
  }
}

class MatchModel {
  MatchModel({
    required this.id,
    required this.createdAt,
    required this.players,
    required this.rounds,
    this.gameMode = GameMode.zeroSum,
    this.raceTarget = 7,
  });

  final String id;
  final DateTime createdAt;
  final List<Player> players;
  final List<RoundModel> rounds;
  final GameMode gameMode;
  final int raceTarget;

  bool get isRaceMode => gameMode == GameMode.raceToRacks;

  Player? get raceWinner {
    if (!isRaceMode) return null;
    for (final player in players) {
      if (scoreFor(player.id) >= raceTarget) {
        return player;
      }
    }
    return null;
  }

  factory MatchModel.createDefault() {
    final now = DateTime.now();
    return MatchModel(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      gameMode: GameMode.zeroSum,
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

  factory MatchModel.createRaceDefault({int raceTarget = 7}) {
    final now = DateTime.now();
    return MatchModel(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      gameMode: GameMode.raceToRacks,
      raceTarget: raceTarget,
      players: [
        Player(
          id: 'p1',
          name: 'Player 1',
          color: const Color(0xFF00E5FF),
        ),
        Player(
          id: 'p2',
          name: 'Player 2',
          color: const Color(0xFFFF4081),
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
    GameMode? gameMode,
    int? raceTarget,
  }) {
    return MatchModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
      gameMode: gameMode ?? this.gameMode,
      raceTarget: raceTarget ?? this.raceTarget,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'players': players.map((p) => p.toJson()).toList(growable: false),
      'rounds': rounds.map((r) => r.toJson()).toList(growable: false),
      'gameMode': gameMode.name,
      'raceTarget': raceTarget,
    };
  }

  static MatchModel fromJson(Map<String, dynamic> json) {
    final modeName = json['gameMode'] as String?;
    final gameMode = GameMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => GameMode.zeroSum,
    );
    final raceTarget = (json['raceTarget'] as num?)?.toInt() ?? 7;

    return MatchModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      rounds: (json['rounds'] as List<dynamic>)
          .map((e) => RoundModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      gameMode: gameMode,
      raceTarget: raceTarget,
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
    final newRound = RoundModel(index: 1, entries: [], createdAt: DateTime.now());
    return copyWith(rounds: [...rounds, newRound]);
  }
}

