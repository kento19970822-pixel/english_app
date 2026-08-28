import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../services/srs_service.dart';
import '../widgets/common/bouncy_scale_tap.dart';
import '../widgets/pixel_character_widget.dart';
import '../widgets/srs_review_dialog.dart';
import 'calendar_screen.dart';
import 'character_gallery_screen.dart';
import 'game_screen.dart';
import 'stamp_gallery_screen.dart';

class ModeSelectScreen extends StatefulWidget {
  final AppDatabase database;
  final Function(int level, String mode, int chapter)? onStartGame;
  final Function(bool isPlaying)? onGameStateChanged;
  final Function(String subView)? onOpenRecordsSubView;

  const ModeSelectScreen({
    super.key,
    required this.database,
    this.onStartGame,
    this.onGameStateChanged,
    this.onOpenRecordsSubView,
  });

  @override
  State<ModeSelectScreen> createState() => ModeSelectScreenState();
}

class ModeSelectScreenState extends State<ModeSelectScreen> {
  final ScrollController _chapterScrollController = ScrollController();

  String selectedMode = 'learning';
  int selectedLevel = 1;
  final Set<int> _selectedLevels = {1};
  int selectedChapter = 1;

  Stamp? _favoriteStamp;
  int _dueCount = 0;
  List<ChapterProgressesData> _allChapterProgresses = [];
  List<ChapterProgressesData> _currentLevelChapters = [];
  bool _isLoadingChapters = false;
  int _chapterLoadRequestId = 0;
  bool _isNavigating = false;

  // テーマカラー
  static const Color _bgColor = Color(0xFFF9F6F0);
  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _borderColor = Color(0xFFE5DEC9);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _secondaryAccent = Color(0xFFD4B86A);
  static const Color _weaknessAccent = Color(0xFFD97736);

  @override
  void initState() {
    super.initState();
    BuddyService.instance.addListener(_onBuddyChanged);
    _favoriteStamp = BuddyService.instance.favoriteStamp;
    _loadChaptersForLevel(selectedLevel);
  }

  void _onBuddyChanged() {
    if (mounted) {
      setState(() {
        _favoriteStamp = BuddyService.instance.favoriteStamp;
      });
    }
  }

  @override
  void dispose() {
    BuddyService.instance.removeListener(_onBuddyChanged);
    _chapterScrollController.dispose();
    super.dispose();
  }

  /// 同じタブを再タップした際の最上部スクロール初期化
  void resetScrollToTop() {
    if (_chapterScrollController.hasClients) {
      _chapterScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadChaptersForLevel(selectedLevel, preserveSelection: true);
  }

  /// 選択中のレベルに対応するチャプター進行状況を取得し、最新解放チャプターを初期選択＆最上部スクロール
  Future<void> _loadChaptersForLevel(int level, {bool preserveSelection = false}) async {
    final requestId = ++_chapterLoadRequestId;

    // メモリ上の進捗データがある場合は即座に切り替え（ローディングスピナーのチラつきを防止）
    if (_allChapterProgresses.isNotEmpty) {
      final cachedFiltered = _allChapterProgresses.where((cp) => cp.level == level).toList();
      final cachedUnlocked = cachedFiltered.where((cp) => cp.isUnlocked).toList();
      final cachedLatest = cachedUnlocked.isNotEmpty
          ? cachedUnlocked.last.chapter
          : (cachedFiltered.isNotEmpty ? cachedFiltered.first.chapter : 1);

      setState(() {
        _currentLevelChapters = cachedFiltered;
        if (!preserveSelection || !cachedFiltered.any((cp) => cp.chapter == selectedChapter)) {
          selectedChapter = cachedLatest;
        }
      });
      _scrollToSelectedChapter(animated: false);
    } else {
      setState(() => _isLoadingChapters = true);
    }

    final results = await Future.wait([
      widget.database.getFavoriteStamp(),
      widget.database.getAllChapterProgresses(),
      SrsService.instance.getDueWordsCount(widget.database),
    ]);

    if (!mounted || requestId != _chapterLoadRequestId) return;

    final favStamp = results[0] as Stamp?;
    final allProgresses = results[1] as List<ChapterProgressesData>;
    final dueCount = results[2] as int;
    
    final filtered = allProgresses.where((cp) => cp.level == level).toList();

    final unlockedList = filtered.where((cp) => cp.isUnlocked).toList();
    final latestUnlocked = unlockedList.isNotEmpty
        ? unlockedList.last.chapter
        : (filtered.isNotEmpty ? filtered.first.chapter : 1);

    setState(() {
      _favoriteStamp = favStamp;
      _dueCount = dueCount;
      _allChapterProgresses = allProgresses;
      _currentLevelChapters = filtered;
      if (!preserveSelection || !filtered.any((cp) => cp.chapter == selectedChapter)) {
        selectedChapter = latestUnlocked;
      }
      _isLoadingChapters = false;
    });

    _scrollToSelectedChapter(animated: true);
  }

  /// 選択中のチャプターがチャプター一覧枠の一番上に表示されるように自動スクロール
  void _scrollToSelectedChapter({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chapterScrollController.hasClients) return;
      final targetIndex = _currentLevelChapters.indexWhere((cp) => cp.chapter == selectedChapter);
      if (targetIndex <= 0) {
        if (animated) {
          _chapterScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        } else {
          _chapterScrollController.jumpTo(0);
        }
        return;
      }

      // チャプターアイテムの高さ(約48px) + 間隔(6px) = 54px
      const itemHeight = 54.0;
      final targetOffset = targetIndex * itemHeight;
      final maxOffset = _chapterScrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxOffset);

      if (animated) {
        _chapterScrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _chapterScrollController.jumpTo(clampedOffset);
      }
    });
  }

  /// 外部（タブ切り替えや単語帳更新時）から最新チャプター進行状況を再ロード
  void reloadChapters() {
    _loadChaptersForLevel(selectedLevel, preserveSelection: true);
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
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      if (selectedMode == 'learning') {
        final selectedProgress = _currentLevelChapters.where(
          (cp) => cp.chapter == selectedChapter,
        ).firstOrNull;

        if (selectedProgress == null || !selectedProgress.isUnlocked) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('このチャプターはまだ解放されていません。前のチャプターをクリアしてください。')),
            );
          }
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
            selectedLevels: selectedMode == 'learning' ? [selectedLevel] : _selectedLevels.toList(),
            initialChapter: selectedChapter,
            autoStart: true,
          ),
        ),
      );

      _loadChaptersForLevel(selectedLevel, preserveSelection: true);
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  void _openSubScreen(Widget screen) {
    if (_isNavigating) return;
    _isNavigating = true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      if (mounted) {
        setState(() => _isNavigating = false);
        _loadChaptersForLevel(selectedLevel, preserveSelection: true);
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 上部固定ヘッダー（タイトル ＆ モード選択 ＆ 難易度レベル選択）
            _buildFixedTopHeader(),

            // 2. 中央エリア（チャプター選択リスト / 弱点克服 / チャレンジ）
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCenterContent(),
              ),
            ),

            // 3. 下部固定エリア（相棒バナー ＆ 開始ボタン）
            _buildFixedBottomBar(),
          ],
        ),
      ),
    );
  }

  /// 上部固定ヘッダー（画面上部に常時収まり見切れゼロ）
  Widget _buildFixedTopHeader() {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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
                onTap: () => _openSubScreen(CalendarScreen(database: widget.database)),
              ),
              const SizedBox(width: 6),
              _buildQuickActionBtn(
                icon: Icons.stars_rounded,
                tooltip: 'スタンプ図鑑',
                onTap: () => _openSubScreen(StampGalleryScreen(database: widget.database)),
              ),
              const SizedBox(width: 6),
              _buildQuickActionBtn(
                icon: Icons.pets_rounded,
                tooltip: 'キャラクター図鑑',
                onTap: () => _openSubScreen(
                  CharacterGalleryScreen(
                    database: widget.database,
                    initialProgresses: _allChapterProgresses,
                    initialFavoriteStamp: _favoriteStamp,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildQuickActionBtn(
                icon: Icons.confirmation_number_rounded,
                iconColor: const Color(0xFFED8936),
                tooltip: 'ひらめき復習チケット',
                badgeCount: _dueCount,
                onTap: () => SrsReviewDialog.show(
                  context,
                  widget.database,
                  onComplete: () => _loadChaptersForLevel(selectedLevel, preserveSelection: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1. プレイモード選択
          const Text(
            'プレイモード',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildModeCard(
                    title: '学習モード',
                    subtitle: '章別集中\n次章解放',
                    icon: Icons.school_rounded,
                    modeKey: 'learning',
                    accentColor: _primaryAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeCard(
                    title: '弱点克服',
                    subtitle: '苦手特訓\n反復学習',
                    icon: Icons.healing_rounded,
                    modeKey: 'weakness',
                    accentColor: _weaknessAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeCard(
                    title: 'チャレンジ',
                    subtitle: '1分/100問\nランダム',
                    icon: Icons.bolt_rounded,
                    modeKey: 'challenge',
                    accentColor: _secondaryAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. 難易度（レベル）選択
          Row(
            children: [
              const Text(
                '難易度レベル',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              if (selectedMode != 'learning') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: (selectedMode == 'weakness' ? _weaknessAccent : _secondaryAccent).withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '複数選択可',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selectedMode == 'weakness' ? _weaknessAccent : _secondaryAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: _buildLevelTab(1, '初級', 'A1/A2')),
              const SizedBox(width: 8),
              Expanded(child: _buildLevelTab(2, '中級', 'B1/B2')),
              const SizedBox(width: 8),
              Expanded(child: _buildLevelTab(3, '上級', 'C1/C2')),
            ],
          ),
        ],
      ),
    );
  }

  /// 中央エリア（学習モード時はチャプター選択・独立スクロール）
  Widget _buildCenterContent() {
    if (selectedMode == 'learning') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: _primaryAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primaryAccent.withAlpha(50), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_open_rounded, size: 11, color: _primaryAccent),
                    SizedBox(width: 3),
                    Text(
                      '70pt以上 90%で次章',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
                        controller: _chapterScrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _currentLevelChapters.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final cp = _currentLevelChapters[index];
                          final isSelected = selectedChapter == cp.chapter;
                          final isUnlocked = cp.isUnlocked;
                          final isCleared = cp.isCleared;

                          return BouncyScaleTap(
                            onTap: isUnlocked
                                ? () {
                                    setState(() {
                                      selectedChapter = cp.chapter;
                                    });
                                  }
                                : null,
                            pressedScale: 0.98,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _primaryAccent.withAlpha(25)
                                    : (isUnlocked ? _cardColor : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _primaryAccent
                                      : (isUnlocked ? _borderColor : Colors.transparent),
                                  width: isSelected ? 1.8 : 1.0,
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
                                        : Colors.grey.shade400,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  PixelCharacterWidget(
                                    speciesIndex: cp.chapter - 1,
                                    growthState: isUnlocked
                                        ? (isCleared
                                            ? CharacterGrowthState.evolved
                                            : PixelCharacterWidget.stateFromRate(cp.memorizedRate, true))
                                        : CharacterGrowthState.locked,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ch.${cp.chapter}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isUnlocked ? _textPrimary : Colors.grey.shade500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isUnlocked) ...[
                                    if (isCleared) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _primaryAccent.withAlpha(20),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.stars_rounded, color: _primaryAccent, size: 13),
                                            const SizedBox(width: 3),
                                            Text(
                                              '達成 ${cp.memorizedRate.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _primaryAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        '${cp.memorizedRate.toStringAsFixed(0)}% (${(cp.memorizedRate).round()}/100)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ] else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_rounded, size: 12, color: Colors.grey.shade400),
                                        const SizedBox(width: 3),
                                        Text(
                                          '未解放',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    } else if (selectedMode == 'weakness') {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DEC9)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded, color: _weaknessAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '弱点克服（リベンジ）特訓',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '選択中レベル（${_selectedLevels.map((l) => l == 1 ? "初級" : (l == 2 ? "中級" : "上級")).join("・")}）の誤答履歴・定着度から苦手単語上位15語を集中反復出題します（複数レベル選択可）。',
                style: const TextStyle(fontSize: 12.5, color: _textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: _secondaryAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '選択中レベル（${_selectedLevels.map((l) => l == 1 ? "初級" : (l == 2 ? "中級" : "上級")).join("・")}）から100問連続でランダム出題されます（制限時間1分間・複数レベル選択可）。',
                  style: const TextStyle(fontSize: 12.5, color: _textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// 下部固定エリア（相棒バナー ＆ 開始ボタン）
  Widget _buildFixedBottomBar() {
    final buddyGrowth = _getBuddyGrowthState();
    final isBuddyLocked = buddyGrowth == CharacterGrowthState.locked;
    final buddySpecies = getCharacterSpecies(BuddyService.instance.selectedSpeciesId + 1);
    final buddyDisplayName = isBuddyLocked ? '？？？？？ (未解放)' : buddySpecies.japaneseName;

    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 相棒ふれあいスペース
          Container(
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
                  growthState: buddyGrowth,
                  actionState: CharacterActionState.idle,
                  favoriteStamp: _favoriteStamp,
                  size: 38,
                  isInteractive: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BouncyScaleTap(
                    onTap: () => _openSubScreen(CharacterGalleryScreen(database: widget.database)),
                    pressedScale: 0.98,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                '相棒: $buddyDisplayName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                '図鑑変更 ➔',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _primaryAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedMode == 'learning'
                                ? 'Ch.$selectedChapter の暗記クリアを目指そう！'
                                : (selectedMode == 'weakness'
                                    ? '苦手な単語を克服して強くなろう！'
                                    : '1分間でハイスコアを目指そう！'),
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
          const SizedBox(height: 8),

          // 学習開始ボタン
          BouncyScaleTap(
            onTap: _startGame,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: selectedMode == 'weakness'
                    ? _weaknessAccent
                    : (selectedMode == 'challenge' ? _secondaryAccent : _primaryAccent),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (selectedMode == 'weakness'
                            ? _weaknessAccent
                            : (selectedMode == 'challenge' ? _secondaryAccent : _primaryAccent))
                        .withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                selectedMode == 'learning'
                    ? 'Chapter $selectedChapter を学習開始'
                    : (selectedMode == 'weakness' ? '弱点克服トレーニングを開始' : 'チャレンジを開始'),
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    Color? iconColor,
    required String tooltip,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BouncyScaleTap(
          onTap: onTap,
          pressedScale: 0.92,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? _primaryAccent,
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: const BoxDecoration(
                color: Color(0xFFED8936),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
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

    return BouncyScaleTap(
      onTap: () {
        setState(() {
          selectedMode = modeKey;
        });
      },
      pressedScale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(25) : _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : _borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? accentColor.withAlpha(30) : const Color(0x06000000),
              blurRadius: isSelected ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withAlpha(35) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? accentColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : _textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? accentColor.withAlpha(200) : _textSecondary,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTab(int level, String title, String subtitle) {
    final isMulti = selectedMode != 'learning';
    final isSelected = isMulti ? _selectedLevels.contains(level) : selectedLevel == level;
    final activeColor = selectedMode == 'weakness'
        ? _weaknessAccent
        : (selectedMode == 'challenge' ? _secondaryAccent : _primaryAccent);

    return BouncyScaleTap(
      onTap: () {
        setState(() {
          if (isMulti) {
            if (_selectedLevels.contains(level)) {
              _selectedLevels.remove(level);
              if (_selectedLevels.isEmpty) {
                _selectedLevels.addAll([1, 2, 3]);
              }
            } else {
              _selectedLevels.add(level);
            }
          } else {
            selectedLevel = level;
            _loadChaptersForLevel(level);
          }
        });
      },
      pressedScale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(25) : _cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : _borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? activeColor : _textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isSelected ? activeColor.withAlpha(200) : _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isMulti && isSelected)
              Positioned(
                top: 0,
                right: 2,
                child: Icon(Icons.check_circle_rounded, size: 12, color: activeColor),
              ),
          ],
        ),
      ),
    );
  }
}
