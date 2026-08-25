import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/app_database.dart';
import 'screens/mode_select_screen.dart';
import 'screens/words_screen.dart';
import 'screens/records_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF7EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5F9E98),
          primary: const Color(0xFF5F9E98),
          secondary: const Color(0xFFECA882),
          surface: const Color(0xFFFFFDF9),
        ),
      ),
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
  final GlobalKey<RecordsScreenState> _recordsKey = GlobalKey<RecordsScreenState>();

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _checkAndRunDailySync();
  }

  /// 1日1回のみ日跨ぎ一括同期（忘却減算・制限解除）を実行 ＆ チャプター進捗初期化
  Future<void> _checkAndRunDailySync() async {
    await _database.initChapterProgresses();
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

  void _onOpenRecordsSubView(String subView) {
    setState(() {
      _selectedIndex = 2;
    });
    _recordsKey.currentState?.openSubView(subView);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ModeSelectScreen(
        database: _database,
        onGameStateChanged: _onGameStateChanged,
        onOpenRecordsSubView: _onOpenRecordsSubView,
      ),
      WordsScreen(database: _database),
      RecordsScreen(
        key: _recordsKey,
        database: _database,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _isGameStarted
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              backgroundColor: const Color(0xFFFFFDF9),
              indicatorColor: const Color(0xFF5F9E98).withAlpha(50),
              onDestinationSelected: (int index) {
                if (index == 2 && _selectedIndex == 2) {
                  // 記録タブがすでに選択されている場合、サブビューからトップメニューへ戻る
                  _recordsKey.currentState?.closeSubView();
                }
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.sports_esports_outlined),
                  selectedIcon: Icon(Icons.sports_esports),
                  label: 'ゲーム',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: '単語一覧',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: '記録',
                ),
              ],
            ),
    );
  }
}
