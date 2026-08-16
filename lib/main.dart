// コード管理番号: VER-20260816-06
import 'package:flutter/material.dart';

import 'db/app_database.dart';
import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  runApp(EnglishQuizApp(database: database));
}

class EnglishQuizApp extends StatelessWidget {
  final AppDatabase database;

  const EnglishQuizApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2レーン並列 英単語クイズ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: GameScreen(database: database),
    );
  }
}
