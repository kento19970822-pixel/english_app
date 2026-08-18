// コード管理番号: VER-20260816-87
import 'package:flutter/material.dart';

import 'db/app_database.dart';
import 'screens/mode_select_screen.dart';
import 'screens/words_screen.dart';

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
              ],
            ),
    );
  }
}
