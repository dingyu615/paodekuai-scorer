import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/game_provider.dart';
import 'services/hive_service.dart';
import 'pages/home/home_page.dart';
import 'pages/create_game/create_game_page.dart';
import 'pages/game/game_page.dart';
import 'pages/result/result_page.dart';
import 'pages/history/history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: '跑得快计分器',
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/':
              page = const HomePage();
              break;
            case '/create-game':
              page = const CreateGamePage();
              break;
            case '/game':
              page = const GamePage();
              break;
            case '/result':
              page = const ResultPage();
              break;
            case '/history':
              page = HistoryPage(showStats: (settings.arguments as bool?) ?? false);
              break;
            default:
              page = const HomePage();
          }
          return MaterialPageRoute(builder: (_) => page);
        },
      ),
    );
  }
}
