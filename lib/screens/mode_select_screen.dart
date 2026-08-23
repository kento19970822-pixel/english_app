// コード管理番号: VER-20260824-03
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import 'game_screen.dart';

class ModeSelectScreen extends StatefulWidget {
  final AppDatabase database;
  final Function(bool isStarted)? onGameStateChanged;

  const ModeSelectScreen({
    super.key,
    required this.database,
    this.onGameStateChanged,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  String selectedMode = 'learning'; // 'learning' or 'challenge'
  int selectedLevel = 1; // 1: 初級, 2: 中級, 3: 上級 (UI上の3区分)
  int selectedChapter = 1;

  List<ChapterProgressesData> _currentLevelChapters = [];
  bool _isLoadingChapters = true;

  // 定数カラーパレット
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
    _loadChaptersForLevel(selectedLevel);
  }

  /// 画面復帰時などに最新チャプター解放状況を再ロード
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadChaptersForLevel(selectedLevel, preserveSelection: true);
  }

  /// 選択中のレベルに対応するチャプター進行状況を取得し、最新解放チャプターを初期選択
  Future<void> _loadChaptersForLevel(int level, {bool preserveSelection = false}) async {
    setState(() => _isLoadingChapters = true);

    // level 1: A1(1), A2(2) / level 2: B1(3), B2(4) / level 3: C1(5), C2(6)
    final allProgresses = await widget.database.getAllChapterProgresses();
    
    // レベルマッピング (初級: lvl 1,2 / 中級: lvl 3,4 / 上級: lvl 5,6)
    final targetLvls = level == 1
        ? [1, 2]
        : level == 2
            ? [3, 4]
            : [5, 6];

    final filtered = allProgresses.where((cp) => targetLvls.contains(cp.level)).toList();

    // 最新解放チャプターの算出 (isUnlocked == true のうち最大チャプター番号)
    final unlockedList = filtered.where((cp) => cp.isUnlocked).toList();
    final latestUnlocked = unlockedList.isNotEmpty
        ? unlockedList.last.chapter
        : (filtered.isNotEmpty ? filtered.first.chapter : 1);

    if (mounted) {
      setState(() {
        _currentLevelChapters = filtered;
        if (!preserveSelection || !filtered.any((cp) => cp.chapter == selectedChapter)) {
          selectedChapter = latestUnlocked;
        }
        _isLoadingChapters = false;
      });
    }
  }

  Future<void> _startGame() async {
    if (selectedMode == 'learning') {
      // 選択チャプターが解放されているか検証
      final selectedProgress = _currentLevelChapters.where(
        (cp) => cp.chapter == selectedChapter,
      ).firstOrNull;

      if (selectedProgress == null || !selectedProgress.isUnlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('このチャプターはまだ解放されていません。前のチャプターをクリアしてください。')),
        );
        return;
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          database: widget.database,
          onGameStateChanged: widget.onGameStateChanged,
          mode: selectedMode,
          initialLevel: selectedLevel,
          initialChapter: selectedChapter,
          autoStart: true,
        ),
      ),
    );

    // ゲーム終了後にチャプター解放状況を更新
    _loadChaptersForLevel(selectedLevel, preserveSelection: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ゲーム選択',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // 1. プレイモード選択
              const Text(
                'プレイモード',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      title: '学習モード',
                      subtitle: '章ごと集中学習\n(暗記90%超で次章解放)',
                      icon: Icons.school_rounded,
                      modeKey: 'learning',
                      accentColor: _primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeCard(
                      title: 'チャレンジ',
                      subtitle: '1分間/100問連続\n全単語ランダム出題',
                      icon: Icons.bolt_rounded,
                      modeKey: 'challenge',
                      accentColor: _secondaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. 難易度（レベル）選択
              const Text(
                '難易度レベル',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _primaryAccent.withAlpha(40);
                    }
                    return _cardColor;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _primaryAccent;
                    }
                    return _textSecondary;
                  }),
                  side: WidgetStateProperty.all(
                    const BorderSide(color: _borderColor),
                  ),
                ),
                segments: const [
                  ButtonSegment(value: 1, label: Text('初級 (A1/A2)')),
                  ButtonSegment(value: 2, label: Text('中級 (B1/B2)')),
                  ButtonSegment(value: 3, label: Text('上級 (C1/C2)')),
                ],
                selected: {selectedLevel},
                onSelectionChanged: (newSelection) {
                  final lvl = newSelection.first;
                  setState(() {
                    selectedLevel = lvl;
                  });
                  _loadChaptersForLevel(lvl);
                },
              ),

              // 3. チャプター選択（学習モード時のみ表示）
              if (selectedMode == 'learning') ...[
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'チャプター選択',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'クリア条件: 暗記率 > 90%',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoadingChapters
                      ? const Center(child: CircularProgressIndicator(color: _primaryAccent))
                      : _currentLevelChapters.isEmpty
                          ? const Center(
                              child: Text(
                                'チャプター情報がありません。単語帳からDBを再構築してください。',
                                style: TextStyle(color: _textSecondary, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _currentLevelChapters.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final cp = _currentLevelChapters[index];
                                final isSelected = selectedChapter == cp.chapter;
                                final isUnlocked = cp.isUnlocked;
                                final isCleared = cp.isCleared;

                                return InkWell(
                                  onTap: isUnlocked
                                      ? () {
                                          setState(() {
                                            selectedChapter = cp.chapter;
                                          });
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _primaryAccent.withAlpha(25)
                                          : (isUnlocked ? _cardColor : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? _primaryAccent
                                            : (isUnlocked ? _borderColor : Colors.transparent),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isUnlocked
                                              ? (isSelected
                                                  ? Icons.radio_button_checked
                                                  : Icons.radio_button_unchecked)
                                              : Icons.lock_outline_rounded,
                                          color: isUnlocked
                                              ? (isSelected ? _primaryAccent : _textSecondary)
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Chapter ${cp.chapter}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isUnlocked ? _textPrimary : Colors.grey,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isCleared)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E9),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.green.shade300),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'クリア (${cp.memorizedRate.toInt()}%)',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (isUnlocked && cp.memorizedRate > 0)
                                          Text(
                                            '暗記率: ${cp.memorizedRate.toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _textSecondary,
                                            ),
                                          )
                                        else if (!isUnlocked)
                                          const Text(
                                            '未解放',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ] else ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: _secondaryAccent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'チャレンジモードは、全レベル・全単語から100問連続でランダム出題されます（制限時間1分間）。',
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],

              const SizedBox(height: 12),

              // 4. ゲーム開始ボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: selectedMode == 'learning' ? _primaryAccent : _secondaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _startGame,
                child: Text(
                  selectedMode == 'learning'
                      ? 'Chapter $selectedChapter を学習開始'
                      : 'チャレンジを開始',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String modeKey,
    required Color accentColor,
  }) {
    final isSelected = selectedMode == modeKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = modeKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(20) : _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : _borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? accentColor : _textSecondary),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

