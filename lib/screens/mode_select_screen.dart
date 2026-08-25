// コード管理番号: VER-20260825-17
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../widgets/pixel_character_widget.dart';
import 'calendar_screen.dart';
import 'character_gallery_screen.dart';
import 'game_screen.dart';
import 'stamp_gallery_screen.dart';

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

  List<ChapterProgressesData> _allChapterProgresses = [];
  List<ChapterProgressesData> _currentLevelChapters = [];
  bool _isLoadingChapters = true;
  Stamp? _favoriteStamp;

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

    final favStamp = await widget.database.getFavoriteStamp();
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
        _favoriteStamp = favStamp;
        _allChapterProgresses = allProgresses;
        _currentLevelChapters = filtered;
        if (!preserveSelection || !filtered.any((cp) => cp.chapter == selectedChapter)) {
          selectedChapter = latestUnlocked;
        }
        _isLoadingChapters = false;
      });
    }
  }

  CharacterGrowthState _getBuddyGrowthState() {
    final buddyId = BuddyService.instance.selectedSpeciesId;
    final matching = _allChapterProgresses.where(
      (cp) => cp.chapter == (buddyId + 1),
    ).firstOrNull;
    if (matching == null) return CharacterGrowthState.locked;
    return PixelCharacterWidget.stateFromRate(matching.memorizedRate, matching.isUnlocked);
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ゲーム選択',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _buildQuickActionBtn(
                          icon: Icons.calendar_month_rounded,
                          tooltip: '学習カレンダー',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CalendarScreen(database: widget.database),
                              ),
                            );
                            _loadChaptersForLevel(selectedLevel, preserveSelection: true);
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionBtn(
                          icon: Icons.stars_rounded,
                          tooltip: 'スタンプ図鑑',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StampGalleryScreen(database: widget.database),
                              ),
                            );
                            _loadChaptersForLevel(selectedLevel, preserveSelection: true);
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionBtn(
                          icon: Icons.pets_rounded,
                          tooltip: 'キャラクター図鑑',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CharacterGalleryScreen(database: widget.database),
                              ),
                            );
                            _loadChaptersForLevel(selectedLevel, preserveSelection: true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 1. プレイモード選択
                    const Text(
                      'プレイモード',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeCard(
                            title: '学習モード',
                            subtitle: '章ごと集中学習\n(70pt以上90%で次章解放)',
                            icon: Icons.school_rounded,
                            modeKey: 'learning',
                            accentColor: _primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
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
                    const SizedBox(height: 12),

                    // 2. 難易度（レベル）選択
                    const Text(
                      '難易度レベル',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildLevelTab(1, '初級', 'A1/A2')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildLevelTab(2, '中級', 'B1/B2')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildLevelTab(3, '上級', 'C1/C2')),
                      ],
                    ),

                    // 3. チャプター選択（学習モード時のみ表示）
                    if (selectedMode == 'learning') ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'チャプター選択',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primaryAccent.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '解放条件: 70pt以上の単語が90%以上',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _isLoadingChapters
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(child: CircularProgressIndicator(color: _primaryAccent)),
                            )
                          : _currentLevelChapters.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: Text(
                                      'チャプター情報がありません。単語帳からDBを再構築してください。',
                                      style: TextStyle(color: _textSecondary, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _currentLevelChapters.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 6),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            // F-13: 章ドットキャラクター（定着率連動）
                                            PixelCharacterWidget(
                                              speciesIndex: cp.chapter - 1,
                                              growthState: PixelCharacterWidget.stateFromRate(
                                                cp.memorizedRate,
                                                isUnlocked,
                                              ),
                                              actionState: isUnlocked && isCleared
                                                  ? CharacterActionState.walk
                                                  : CharacterActionState.idle,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Chapter ${cp.chapter}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isUnlocked ? _textPrimary : Colors.grey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            if (isCleared)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE8F5E9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.green.shade300),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'クリア (${cp.memorizedRate.toInt()}%)',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else if (isUnlocked && cp.memorizedRate > 0)
                                              Text(
                                                '70pt以上: ${cp.memorizedRate.toInt()}%',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else if (!isUnlocked)
                                              const Text(
                                                '未解放',
                                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _borderColor),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: _secondaryAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'チャレンジモードは、全レベル・全単語から100問連続でランダム出題されます（制限時間1分間）。',
                                style: TextStyle(fontSize: 12, color: _textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // F-14: 相棒ふれあいスペース（待機・歩行・タップでハミング・胸バッジ合成）
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  PixelCharacterWidget(
                    speciesIndex: BuddyService.instance.selectedSpeciesId,
                    growthState: _getBuddyGrowthState(),
                    actionState: CharacterActionState.idle,
                    favoriteStamp: _favoriteStamp,
                    size: 38,
                    isInteractive: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterGalleryScreen(database: widget.database),
                          ),
                        );
                        _loadChaptersForLevel(selectedLevel, preserveSelection: true);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '相棒: ${getCharacterSpecies(BuddyService.instance.selectedSpeciesId + 1).japaneseName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  '図鑑変更 ➔',
                                  style: TextStyle(fontSize: 10, color: _primaryAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedMode == 'learning'
                                  ? 'Ch.$selectedChapter の暗記クリアを目指そう！'
                                  : '制限時間1分間でスコアアタックに挑戦！',
                              style: const TextStyle(fontSize: 11, color: _textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 常時下部に固定配置された開始ボタン（スクロール不要で即座に押せる・iPhone Safe Area対応）
            SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: const BoxDecoration(
                  color: _bgColor,
                  border: Border(top: BorderSide(color: _borderColor)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: selectedMode == 'learning' ? _primaryAccent : _secondaryAccent,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _startGame,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        selectedMode == 'learning'
                            ? 'Chapter $selectedChapter を学習開始'
                            : 'チャレンジを開始',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
            ),
            child: Icon(icon, size: 20, color: _primaryAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelTab(int level, String title, String subtitle) {
    final isSelected = selectedLevel == level;

    return InkWell(
      onTap: () {
        setState(() {
          selectedLevel = level;
        });
        _loadChaptersForLevel(level);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? _primaryAccent.withAlpha(35) : _cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryAccent : _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? _primaryAccent : _textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? _primaryAccent : _textSecondary,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(20) : _cardColor,
          borderRadius: BorderRadius.circular(14),
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
            Icon(icon, size: 28, color: isSelected ? accentColor : _textSecondary),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : _textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

