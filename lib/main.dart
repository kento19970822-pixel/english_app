import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/app_database.dart';
import 'screens/mode_select_screen.dart';
import 'screens/words_screen.dart';
import 'screens/calendar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '英単語ゲーム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  late final AppDatabase _database;
  int _selectedIndex = 0;
  bool _isGameStarted = false;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _checkAndRunDailySync();
  }

  /// 1日1回のみ日跨ぎ一括同期（忘却減算・制限解除）を実行
  Future<void> _checkAndRunDailySync() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final lastSyncDate = prefs.getString('last_daily_sync_date');

    // 日付が変わっている場合のみ実行
    if (lastSyncDate != todayStr) {
      await _database.syncDailyForgettingAndRestrictions();
      await prefs.setString('last_daily_sync_date', todayStr);
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  void _onGameStateChanged(bool isStarted) {
    setState(() {
      _isGameStarted = isStarted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ModeSelectScreen(
        database: _database,
        onGameStateChanged: _onGameStateChanged,
      ),
      WordsScreen(database: _database),
      CalendarScreen(database: _database),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _isGameStarted
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.sports_esports),
                  label: 'ゲーム',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt),
                  label: '単語一覧',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month),
                  label: 'カレンダー',
                ),
              ],
            ),
    );
  }
}
