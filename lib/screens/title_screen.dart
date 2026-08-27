import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../main.dart';
import '../services/buddy_service.dart';
import '../widgets/pixel_character_widget.dart';

class TitleScreen extends StatefulWidget {
  final AppDatabase database;

  const TitleScreen({super.key, required this.database});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _streakCount = 0;
  int _totalDays = 0;
  Stamp? _favoriteStamp;
  CharacterGrowthState _buddyGrowth = CharacterGrowthState.healthy;
  bool _isLoading = true;
  bool _isTransitioning = false;

  // 定数パステルカラー
  static const Color _bgColor = Color(0xFFFBF7EE);
  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _secondaryAccent = Color(0xFFECA882);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _borderColor = Color(0xFFE5DEC9);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadInitialData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await widget.database.initWordsIfEmpty();
      await widget.database.initChapterProgresses();
      final streak = await widget.database.calculateStreak();
      final totalDays = await widget.database.calculateTotalStudiedDays();
      final favStamp = await widget.database.getFavoriteStamp();

      final buddyId = BuddyService.instance.selectedSpeciesId;
      final progresses = await widget.database.getAllChapterProgresses();
      final buddyProgress = progresses.where((cp) => cp.chapter == (buddyId + 1)).firstOrNull;

      final growth = buddyProgress != null
          ? PixelCharacterWidget.stateFromRate(buddyProgress.memorizedRate, buddyProgress.isUnlocked)
          : CharacterGrowthState.healthy;

      if (mounted) {
        setState(() {
          _streakCount = streak;
          _totalDays = totalDays;
          _favoriteStamp = favStamp;
          _buddyGrowth = growth == CharacterGrowthState.locked ? CharacterGrowthState.healthy : growth;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Title load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStart() {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, anim, secAnim) => const MainHomeScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _primaryAccent),
                  SizedBox(height: 16),
                  Text(
                    'データを準備中...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onStart,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // 1. タイトルロゴ（プロシージャル・ドット風フレーム）
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _borderColor, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: _secondaryAccent, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'ENGLISH QUEST',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: _primaryAccent,
                                    shadows: [
                                      Shadow(
                                        color: _primaryAccent.withAlpha(50),
                                        offset: const Offset(1, 2),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.auto_awesome_rounded, color: _secondaryAccent, size: 22),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '落下パズル × 忘却曲線 英単語ゲーム',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // 2. メインビジュアル: 相棒キャラクター ＆ ドットステージ
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelCharacterWidget(
                            speciesIndex: BuddyService.instance.selectedSpeciesId,
                            growthState: _buddyGrowth,
                            actionState: CharacterActionState.walk,
                            favoriteStamp: _favoriteStamp,
                            size: 96,
                            isInteractive: true,
                          ),
                          const SizedBox(height: 8),
                          // レトロステージ台座
                          Container(
                            width: 140,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _borderColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0E000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(flex: 2),

                      // 3. 学習ステータスバッジ（連続日数・累計日数）
                      if (_streakCount > 0 || _totalDays > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: _secondaryAccent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$_streakCount 日連続学習中！',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '(累計 $_totalDays 日)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 4. TAP TO START 点滅アニメーションボタン
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final opacity = 0.4 + (_animController.value * 0.6);
                          return Opacity(
                            opacity: opacity,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _primaryAccent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryAccent.withAlpha(80),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 6),
                                  Text(
                                    'TAP TO START',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const Spacer(flex: 1),

                      // 5. フッター（バージョン表記）
                      const Text(
                        'Version 1.0.0 • Offline Ready',
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
