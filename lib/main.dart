import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cubit/match_board_cubit.dart';
import 'cubit/match_board_state.dart';
import 'models/match.dart';
import 'screens/history_screen.dart';
import 'screens/match_screen.dart';
import 'services/wakelock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await WakelockService.enable();
  runApp(const ScoreBoardApp());
}

class ScoreBoardApp extends StatefulWidget {
  const ScoreBoardApp({super.key});

  @override
  State<ScoreBoardApp> createState() => _ScoreBoardAppState();
}

class _ScoreBoardAppState extends State<ScoreBoardApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockService.enable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đánh Đền',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        textTheme: GoogleFonts.orbitronTextTheme(),
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
        return MatchScreen(onOpenHistory: () => _openHistory(context));
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
