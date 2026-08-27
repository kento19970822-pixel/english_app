// コード管理番号: VER-20260825-17
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../widgets/pixel_character_widget.dart';
import 'calendar_screen.dart';
import 'character_gallery_screen.dart';
import 'game_screen.dart';
import 'stamp_gallery_screen.dart';
import '../widgets/srs_review_dialog.dart';

class ModeSelectScreen extends StatefulWidget {
  final AppDatabase database;
  final ValueChanged<bool>? onGameStateChanged;
  final ValueChanged<String>? onOpenRecordsSubView;

  const ModeSelectScreen({
    super.key,
    required this.database,
    this.onGameStateChanged,
    this.onOpenRecordsSubView,
  });

  @override
  State<ModeSelectScreen> createState() => ModeSelectScreenState();
}

class ModeSelectScreenState extends State<ModeSelectScreen> {
  String selectedMode = 'learning'; // 'learning', 'weakness', or 'challenge'
  int selectedLevel = 1; // 1: 初級, 2: 中級, 3: 上級 (UI上の3区分 - 学習モード用)
  final Set<int> _selectedLevels = {1, 2, 3}; // 弱点克服・チャレンジ用複数レベル選択（デフォルト全選択）
  int selectedChapter = 1;

  List<ChapterProgressesData> _allChapterProgresses = [];
  List<ChapterProgressesData> _currentLevelChapters = [];
  bool _isLoadingChapters = true;
  Stamp? _favoriteStamp;
  final ScrollController _scrollController = ScrollController();

  // 定数カラーパレット
  static const Color _bgColor = Color(0xFFFBF7EE);
  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _secondaryAccent = Color(0xFFECA882);
  static const Color _weaknessAccent = Color(0xFFCF7067);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _borderColor = Color(0xFFE5DEC9);

  @override
  void initState() {
    super.initState();
    BuddyService.instance.addListener(_onBuddyChanged);
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
    _scrollController.dispose();
    super.dispose();
  }

  /// 同じタブを再タップした際の最上部スクロール初期化 (項目12)
  void resetScrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
    final allProgresses = await widget.database.getAllChapterProgresses();
    
    // レベルマッピング (初級: lvl 1 / 中級: lvl 2 / 上級: lvl 3)
    final filtered = allProgresses.where((cp) => cp.level == level).toList();

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
          selectedLevels: selectedMode == 'learning' ? [selectedLevel] : _selectedLevels.toList(),
          initialChapter: selectedChapter,
          autoStart: true,
        ),
      ),
    );

    // ゲーム終了後にチャプター解放状況を更新
    _loadChaptersForLevel(selectedLevel, preserveSelection: true);
  }

  void _openSubScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _loadChaptersForLevel(selectedLevel, preserveSelection: true));
  }

  @override
  Widget build(BuildContext context) {
    final buddyGrowth = _getBuddyGrowthState();
    final isBuddyLocked = buddyGrowth == CharacterGrowthState.locked;
    final buddySpecies = getCharacterSpecies(BuddyService.instance.selectedSpeciesId + 1);
    final buddyDisplayName = isBuddyLocked ? '？？？？？ (未解放)' : buddySpecies.japaneseName;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // スクロール時に隠れ、下スクロール（引き下げ）で単語帳同様に再表示されるフローティングヘッダー (項目6)
                  SliverAppBar(
                    floating: true,
                    snap: false,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: _bgColor,
                    elevation: 0,
                    toolbarHeight: 285,
                    expandedHeight: 285,
                    collapsedHeight: 285,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
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
                                  onTap: () => _openSubScreen(CharacterGalleryScreen(database: widget.database)),
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
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildModeCard(
                                      title: '学習モード',
                                      subtitle: '章ごと集中学習\n暗記で次章解放',
                                      icon: Icons.school_rounded,
                                      modeKey: 'learning',
                                      accentColor: _primaryAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildModeCard(
                                      title: '弱点克服',
                                      subtitle: '誤答・低定着の\n苦手単語を特訓',
                                      icon: Icons.healing_rounded,
                                      modeKey: 'weakness',
                                      accentColor: _weaknessAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildModeCard(
                                      title: 'チャレンジ',
                                      subtitle: '1分間/100問\n全単語ランダム',
                                      icon: Icons.bolt_rounded,
                                      modeKey: 'challenge',
                                      accentColor: _secondaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // チャプター一覧・弱点克服案内・チャレンジ案内 ＆ 相棒バナー
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // SRS 能動的想起（Active Recall）復習バナー
                          InkWell(
                            onTap: () => SrsReviewDialog.show(
                              context,
                              widget.database,
                              onComplete: () => setState(() {}),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFED8936).withAlpha(35),
                                    const Color(0xFF5F9E98).withAlpha(25),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFED8936).withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFED8936),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SRS 能動的想起（Active Recall）',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '忘却曲線に基づく本日の最適復習を開始',
                                          style: TextStyle(fontSize: 10.5, color: _textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: _textSecondary, size: 20),
                                ],
                              ),
                            ),
                          ),

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
                                                      color: isUnlocked ? _textPrimary : Colors.grey,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  if (isUnlocked) ...[
                                                    Text(
                                                      '${cp.memorizedRate.toStringAsFixed(0)}% (${(cp.memorizedRate).round()}/100)',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isCleared ? _primaryAccent : _textSecondary,
                                                        fontWeight: isCleared ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                    if (isCleared) ...[
                                                      const SizedBox(width: 4),
                                                      const Icon(Icons.check_circle_rounded, color: _primaryAccent, size: 14),
                                                    ],
                                                  ] else
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
                          ] else if (selectedMode == 'weakness') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5DEC9)),
                              ),
                              child: Column(
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
                                  const SizedBox(height: 6),
                                  Text(
                                    '選択中レベル（${_selectedLevels.map((l) => l == 1 ? "初級" : (l == 2 ? "中級" : "上級")).join("・")}）の誤答履歴・定着度から苦手単語上位15語を集中反復出題します（複数レベル選択可）。',
                                    style: const TextStyle(fontSize: 12, color: _textSecondary, height: 1.4),
                                  ),
                                ],
                              ),
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
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: _secondaryAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '選択中レベル（${_selectedLevels.map((l) => l == 1 ? "初級" : (l == 2 ? "中級" : "上級")).join("・")}）から100問連続でランダム出題されます（制限時間1分間・複数レベル選択可）。',
                                      style: const TextStyle(fontSize: 12, color: _textSecondary),
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
                ],
              ),
            ),

            // F-14: 相棒ふれあいスペース（常時固定表示・待機・歩行・タップで図鑑）
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
                    growthState: buddyGrowth,
                    actionState: CharacterActionState.idle,
                    favoriteStamp: _favoriteStamp,
                    size: 38,
                    isInteractive: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openSubScreen(CharacterGalleryScreen(database: widget.database)),
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
                              isBuddyLocked
                                  ? 'Ch.${buddySpecies.chapter} の暗記クリアで解放！'
                                  : (selectedMode == 'learning'
                                      ? 'Ch.$selectedChapter の暗記クリアを目指そう！'
                                      : (selectedMode == 'weakness'
                                          ? '苦手な単語を克服して、記憶を定着させよう！'
                                          : '制限時間1分間でスコアアタックに挑戦！')),
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textSecondary,
                              ),
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
                      backgroundColor: selectedMode == 'learning'
                          ? _primaryAccent
                          : (selectedMode == 'weakness' ? _weaknessAccent : _secondaryAccent),
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
                            : (selectedMode == 'weakness' ? '弱点克服特訓を開始' : 'チャレンジを開始'),
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
    final isMulti = selectedMode != 'learning';
    final isSelected = isMulti ? _selectedLevels.contains(level) : selectedLevel == level;
    final activeColor = selectedMode == 'weakness'
        ? _weaknessAccent
        : (selectedMode == 'challenge' ? _secondaryAccent : _primaryAccent);

    return InkWell(
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(35) : _cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : _borderColor,
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
                  color: isSelected ? activeColor : _textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? activeColor : _textSecondary,
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
          if (modeKey != 'learning' && _selectedLevels.isEmpty) {
            _selectedLevels.addAll([1, 2, 3]);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withAlpha(30) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? accentColor : _textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : _textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 24,
              child: Center(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: _textSecondary, height: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

