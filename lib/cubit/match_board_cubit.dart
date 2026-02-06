import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/match.dart';
import 'match_board_state.dart';

const _storageKey = 'matches';
const int maxMatchHistory = 20;

class MatchBoardCubit extends Cubit<MatchBoardState> {
  MatchBoardCubit() : super(const MatchBoardState(matches: []));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    List<MatchModel> matches = [];
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      matches = decoded
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Trim to last 20 matches if needed
    if (matches.length > maxMatchHistory) {
      matches = matches.sublist(matches.length - maxMatchHistory);
      await _save(matches);
    }
    if (matches.isEmpty) {
      final defaultMatch = MatchModel.createDefault();
      matches = [defaultMatch];
      await _save(matches);
    }
    final currentMatch = matches.last;
    emit(MatchBoardState(
      matches: matches,
      currentMatch: currentMatch,
      loading: false,
    ));
  }

  Future<void> _save(List<MatchModel> matches) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only the last 20 matches
    final trimmedMatches = matches.length > maxMatchHistory
        ? matches.sublist(matches.length - maxMatchHistory)
        : matches;
    final encoded =
        jsonEncode(trimmedMatches.map((m) => m.toJson()).toList(growable: false));
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> updateMatch(MatchModel updated) async {
    final list = List<MatchModel>.from(state.matches);
    final index = list.indexWhere((m) => m.id == updated.id);
    if (index >= 0) {
      list[index] = updated;
    } else {
      list.add(updated);
    }
    await _save(list);
    emit(state.copyWith(matches: list, currentMatch: updated));
  }

  Future<void> newMatch() async {
    final newMatch = MatchModel.createDefault();
    final list = [...state.matches, newMatch];
    await _save(list);
    emit(state.copyWith(matches: list, currentMatch: newMatch));
  }

  void selectMatch(MatchModel match) {
    emit(state.copyWith(currentMatch: match));
  }
}
