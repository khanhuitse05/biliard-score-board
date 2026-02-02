import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/match_board_cubit.dart';
import 'cubit/match_board_state.dart';
import 'models/match.dart';
import 'screens/history_screen.dart';
import 'screens/match_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScoreBoardApp());
}

class ScoreBoardApp extends StatelessWidget {
  const ScoreBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billiard Score Board',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'BitcountSingle',
      ),
      home: BlocProvider(
        create: (context) => MatchBoardCubit()..load(),
        child: const _RootView(),
      ),
    );
  }
}

class _RootView extends StatelessWidget {
  const _RootView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBoardCubit, MatchBoardState>(
      builder: (context, state) {
        if (state.loading || state.currentMatch == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return MatchScreen(
          onOpenHistory: () => _openHistory(context),
        );
      },
    );
  }

  Future<void> _openHistory(BuildContext context) async {
    final cubit = context.read<MatchBoardCubit>();
    final state = cubit.state;
    final selected = await Navigator.of(context).push<MatchModel>(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          matches: state.matches,
          currentMatchId: state.currentMatch?.id,
        ),
      ),
    );
    if (selected != null) {
      cubit.selectMatch(selected);
    }
  }
}
