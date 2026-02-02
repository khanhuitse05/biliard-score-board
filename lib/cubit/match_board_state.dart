import '../models/match.dart';

class MatchBoardState {
  const MatchBoardState({
    required this.matches,
    this.currentMatch,
    this.loading = true,
  });

  final List<MatchModel> matches;
  final MatchModel? currentMatch;
  final bool loading;

  MatchBoardState copyWith({
    List<MatchModel>? matches,
    MatchModel? currentMatch,
    bool? loading,
  }) {
    return MatchBoardState(
      matches: matches ?? this.matches,
      currentMatch: currentMatch ?? this.currentMatch,
      loading: loading ?? this.loading,
    );
  }
}
