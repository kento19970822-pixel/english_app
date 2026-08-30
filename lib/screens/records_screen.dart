// コード管理番号: VER-20260826-RECORDS-CUPERTINO
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../widgets/pixel_character_widget.dart';
import 'calendar_screen.dart';
import 'character_gallery_screen.dart';
import 'stamp_gallery_screen.dart';

/// 「記録」タブ画面 (F-15)
/// カレンダー、スタンプ図鑑、キャラクター図鑑への導線を提供
class RecordsScreen extends StatefulWidget {
  final AppDatabase database;
  final String? initialSubView;
  final ValueChanged<String?>? onSubViewChanged;

  const RecordsScreen({
    super.key,
    required this.database,
    this.initialSubView,
    this.onSubViewChanged,
  });

  @override
  State<RecordsScreen> createState() => RecordsScreenState();
}

class RecordsScreenState extends State<RecordsScreen> {
  int _streakDays = 0;
  int _totalStudiedDays = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    if (widget.initialSubView != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openSubView(widget.initialSubView!);
      });
    }
  }

  bool _isNavigating = false;

  void openSubView(String viewKey) {
    if (_isNavigating) return;

    Widget? targetScreen;
    if (viewKey == 'calendar') {
      targetScreen = CalendarScreen(database: widget.database);
    } else if (viewKey == 'stamp') {
      targetScreen = StampGalleryScreen(database: widget.database);
    } else if (viewKey == 'character') {
      targetScreen = CharacterGalleryScreen(database: widget.database);
    }

    if (targetScreen != null) {
      _isNavigating = true;
      widget.onSubViewChanged?.call(viewKey);
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => targetScreen!),
      ).then((_) {
        if (mounted) {
          setState(() => _isNavigating = false);
          widget.onSubViewChanged?.call(null);
          _loadSummary();
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => _isNavigating = false);
        }
      });
    }
  }

  void closeSubView() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final streak = await widget.database.calculateStreak();
    final totalDays = await widget.database.calculateTotalStudiedDays();
    if (mounted) {
      setState(() {
        _streakDays = streak;
        _totalStudiedDays = totalDays;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFBF7EE);
    const primaryColor = Color(0xFF5F9E98);
    const secondaryColor = Color(0xFFECA882);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          '学習の記録',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C302E),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // ストリークバナー
                  _buildStreakCard(secondaryColor),
                  const SizedBox(height: 20),

                  const Text(
                    '記録メニュー',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C302E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. カレンダー
                  _buildMenuCard(
                    title: '学習カレンダー',
                    subtitle: '日別の暗記達成数とプレイ履歴を確認',
                    icon: Icons.calendar_month_rounded,
                    accentColor: primaryColor,
                    badgeText: '日別達成',
                    onTap: () => openSubView('calendar'),
                  ),
                  const SizedBox(height: 16),

                  // 2. スタンプ図鑑
                  _buildMenuCard(
                    title: 'スタンプ図鑑',
                    subtitle: '毎日の初回クリアで獲得したドット絵スタンプ',
                    icon: Icons.stars_rounded,
                    accentColor: const Color(0xFFD4B86A),
                    badgeText: '全24種',
                    onTap: () => openSubView('stamp'),
                  ),
                  const SizedBox(height: 16),

                  // 3. キャラクター図鑑
                  _buildMenuCard(
                    title: 'キャラクター図鑑',
                    subtitle: '全$kTotalChapterCountチャプターのドット絵キャラ＆相棒設定',
                    icon: Icons.pets_rounded,
                    accentColor: const Color(0xFF88A0A8),
                    badgeText: '全$kTotalChapterCount体',
                    onTap: () => openSubView('character'),
                  ),
                  const SizedBox(height: 24),

                  // 4. 学習記録のリセット
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFFD9534F)),
                      label: const Text(
                        '全学習データ・進捗を完全リセット（初期化）',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD9534F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _showResetConfirmDialog,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD9534F)),
            SizedBox(width: 8),
            Text('全学習データ・進捗の完全リセット', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'チャプター解放、キャラクター図鑑、スタンプ、学習履歴、連続学習日数、暗記進捗のすべてが初期状態に戻ります。\n\n全キャラクターが初期の黒シルエットに戻ります。この操作は取り消せません。実行しますか？',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B726E), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: Color(0xFF888F8C))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.database.resetAllLearningData();
              await _loadSummary();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF5F9E98),
                    content: Text('すべての学習進捗・記録を初期化しました'),
                  ),
                );
              }
            },
            child: const Text('初期化する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 連続日数アイコン
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: accentColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '現在の連続学習日数',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B726E),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$_streakDays',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '日連続プレイ中！',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C302E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 累計学習日数バッジ (F-15)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '累計学習日数',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalStudiedDays 日',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DEC9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C302E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B726E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B726E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
