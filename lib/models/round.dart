class RoundEntry {
  RoundEntry({
    required this.playerId,
    required this.delta,
  });

  final String playerId;
  final int delta;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'delta': delta,
    };
  }

  static RoundEntry fromJson(Map<String, dynamic> json) {
    return RoundEntry(
      playerId: json['playerId'] as String,
      delta: json['delta'] as int,
    );
  }
}

class RoundModel {
  RoundModel({
    required this.index,
    required this.entries,
  });

  final int index;
  final List<RoundEntry> entries;

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    };
  }

  static RoundModel fromJson(Map<String, dynamic> json) {
    return RoundModel(
      index: json['index'] as int,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => RoundEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int totalForPlayer(String playerId) {
    return entries
        .where((e) => e.playerId == playerId)
        .fold(0, (sum, e) => sum + e.delta);
  }

  int get roundTotal =>
      entries.fold<int>(0, (sum, e) => sum + e.delta);
}

