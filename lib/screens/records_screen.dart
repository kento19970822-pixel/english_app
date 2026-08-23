// コード管理番号: VER-20260824-02
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import 'calendar_screen.dart';

/// 「記録」タブ画面 (F-15)
/// カレンダー、スタンプ図鑑、キャラクター図鑑への導線を提供
class RecordsScreen extends StatefulWidget {
  final AppDatabase database;

  const RecordsScreen({super.key, required this.database});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  int _streakDays = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final streak = await widget.database.calculateStreak();
    if (mounted) {
      setState(() {
        _streakDays = streak;
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CalendarScreen(database: widget.database),
                        ),
                      ).then((_) => _loadSummary());
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. スタンプ図鑑
                  _buildMenuCard(
                    title: 'スタンプ図鑑',
                    subtitle: '毎日の初回クリアで獲得したドット絵スタンプ',
                    icon: Icons.verified_rounded,
                    accentColor: const Color(0xFFD4B86A),
                    badgeText: 'F-11/F-12',
                    onTap: () {
                      _showComingSoonDialog(
                        title: 'スタンプ図鑑',
                        message: 'プロシージャル生成ドット絵スタンプ図鑑機能は近日公開予定です！',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. キャラクター図鑑
                  _buildMenuCard(
                    title: 'キャラクター図鑑',
                    subtitle: '解放された章ドットキャラの確認＆相棒設定',
                    icon: Icons.cruelty_free_rounded, // かわいい生き物アイコン
                    accentColor: const Color(0xFF88A0A8),
                    badgeText: 'F-12/F-14',
                    onTap: () {
                      _showComingSoonDialog(
                        title: 'キャラクター図鑑',
                        message: '相棒ドットキャラクター図鑑機能は近日公開予定です！',
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: accentColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '現在の連続学習日数',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B726E),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_streakDays',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '日連続プレイ中！',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C302E),
                      ),
                    ),
                  ],
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
          padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C302E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B726E),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B726E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF5F9E98)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C302E),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF6B726E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '閉じる',
              style: TextStyle(
                color: Color(0xFF5F9E98),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
