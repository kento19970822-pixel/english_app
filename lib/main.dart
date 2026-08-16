// コード管理番号: VER-20260816-24
import 'package:flutter/material.dart';

import 'db/app_database.dart';
import 'screens/game_screen.dart';
import 'screens/words_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '英単語アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: MainNavigationScreen(database: database),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final AppDatabase database;

  const MainNavigationScreen({super.key, required this.database});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isQuizActive = false; // クイズが開始中かどうかを管理

  @override
  Widget build(BuildContext context) {
    final screens = [
      GameScreen(
        database: widget.database,
        // クイズの状態が変化したときにタブの表示/非表示を切り替える
        onGameStateChanged: (isStarted) {
          setState(() {
            _isQuizActive = isStarted;
          });
        },
      ),
      WordsScreen(database: widget.database),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      // クイズ実行中は下部ナビゲーションバーを非表示（null）にする
      bottomNavigationBar: _isQuizActive
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_esports),
                  label: 'クイズ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book),
                  label: '単語帳',
                ),
              ],
            ),
    );
  }
}
