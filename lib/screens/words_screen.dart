// コード管理番号: VER-20260826-08
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';
import '../widgets/custom_fast_scrollbar.dart';
import '../widgets/word_card_tile.dart';
import '../widgets/word_detail_modal.dart';
import '../widgets/word_filter_bottom_sheet.dart';

import '../models/word_section.dart';
import '../theme/app_theme.dart';
import '../widgets/words/word_search_bar.dart';
import '../widgets/words/word_section_sticky_header.dart';
import '../widgets/words/word_chapter_banner.dart';
import '../widgets/common/bouncy_scale_tap.dart';
import 'flashcard_screen.dart';



class WordsScreen extends StatefulWidget {
  final AppDatabase database;

  const WordsScreen({super.key, required this.database});

  @override
  State<WordsScreen> createState() => WordsScreenState();
}

class WordsScreenState extends State<WordsScreen> {
  List<Word> _allWords = [];
  List<WordSection> _sections = [];
  Map<int, ({int total, int memorized})> _chapterGlobalStats = {};
  int _totalFilteredCount = 0;
  int _lastLoadedWordsVersion = 0;

  // ソート・フィルター状態
  String _sortMode = 'chap'; // 'az', 'chap', 'category'
  bool _filterUnlearned = false; // 未暗記トグル
  bool _filterFavorite = false; // お気に入りトグル
  String _selectedCefr = 'ALL'; // 'ALL', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'
  int _selectedChap = 0; // 0: ALL, 1: Ch.1, 2: Ch.2...
  String _selectedAz = 'ALL'; // 'ALL', 'A', 'B', 'C'...
  String _selectedCategory = 'ALL'; // 'ALL', 'General'...
  bool _showJapanese = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _filterScrollController = ScrollController();
  bool _showScrollToTop = false;

  // パステルテーマカラー（ライト/ダーク動的対応）
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgColor => _isDark ? AppTheme.darkBg : AppTheme.lightBg;
  Color get _cardColor => _isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get _primaryAccent => _isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
  Color get _secondaryAccent => _isDark ? AppTheme.darkSecondary : AppTheme.lightSecondary;
  Color get _textPrimary => _isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  Color get _textSecondary => _isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get _borderColor => _isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    BuddyService.instance.addListener(_onBuddyChanged);
    SoundService.instance.initialize();
    _initTts();
    _loadWords();
  }

  void _onBuddyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 300;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// 暗記特化スワイプフラッシュカードモードを開始
  void _startFlashcard(List<Word> targetWords, String title) {
    if (targetWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学習対象の単語がありません')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          database: widget.database,
          words: targetWords,
          title: title,
        ),
      ),
    );
  }

  /// 全セクションの正確な開始スクロールオフセットリストを算出 (Prefix Sums による累積誤差ゼロ計算)
  List<double> _calculateSectionOffsets() {
    if (_sections.isEmpty) return [0.0];

    final double appBarHeight = _activeFilterCount > 0 ? 155.0 : 128.0;
    final double headerHeight = 44.0;
    final double bannerHeight = _sortMode == 'chap' ? 78.0 : 0.0;
    final double tileHeight = 120.0;

    final List<double> offsets = [0.0]; // インデックス0: 画面最上部（SliverAppBar含む）
    double currentAccumulated = appBarHeight;

    for (int i = 0; i < _sections.length; i++) {
      if (i > 0) {
        offsets.add(currentAccumulated);
      }
      final section = _sections[i];
      final sectionHeight = headerHeight + bannerHeight + (section.words.length * tileHeight);
      currentAccumulated += sectionHeight;
    }

    return offsets;
  }

  /// 前のセクション（チャプター・文字・カテゴリ）の先頭へスムーズにスクロール移動 (ズレ 0px)
  void _scrollToPreviousSection() {
    if (!_scrollController.hasClients || _sections.isEmpty) return;

    final currentOffset = _scrollController.offset;
    final offsets = _calculateSectionOffsets();

    // 現在位置より手前にある直近のセクションオフセットを探索
    double targetOffset = 0.0;
    for (int i = offsets.length - 1; i >= 0; i--) {
      if (offsets[i] < currentOffset - 8.0) {
        targetOffset = offsets[i];
        break;
      }
    }

    final maxExtent = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );

    HapticFeedback.lightImpact();
  }

  /// 次のセクション（チャプター・文字・カテゴリ）の先頭へスムーズにスクロール移動 (ズレ 0px)
  void _scrollToNextSection() {
    if (!_scrollController.hasClients || _sections.isEmpty) return;

    final currentOffset = _scrollController.offset;
    final offsets = _calculateSectionOffsets();

    // 現在位置より先にある直近のセクションオフセットを探索
    double? nextOffset;
    for (int i = 0; i < offsets.length; i++) {
      if (offsets[i] > currentOffset + 8.0) {
        nextOffset = offsets[i];
        break;
      }
    }

    final targetOffset = nextOffset ?? 0.0; // 末尾の場合は先頭へループ
    final maxExtent = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );

    HapticFeedback.lightImpact();
  }

  /// タブ再押下時などの画面表示初期化 (要件2: スムーズな一連の初期化アニメーション)
  void resetFiltersAndScrollToTop() {
    // 1. キーボードを閉じる
    FocusScope.of(context).unfocus();

    // 2. フィルター横スクロールを最左端へスムーズに戻す
    if (_filterScrollController.hasClients) {
      _filterScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    // 3. 単語リストを最上部へスムーズにスクロール
    _scrollToTop();

    // 4. フィルター状態のリセットと再描画
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterUnlearned = false;
      _filterFavorite = false;
      _selectedCefr = 'ALL';
      _selectedChap = 0;
      _selectedAz = 'ALL';
      _selectedCategory = 'ALL';
      _sortMode = 'chap';
      _showJapanese = true;
    });
    _applyFilterAndGrouping();
  }

  /// 暗記フラグ再同期確認ダイアログ (忘却等で80pt未満になった単語の暗記フラグを取り外し) (F-09)
  Future<void> _showSyncMemorizedFlagsDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.published_with_changes_rounded, color: _primaryAccent, size: 24),
            SizedBox(width: 8),
            Text(
              '暗記フラグの再同期',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
            ),
          ],
        ),
        content: Text(
          '忘却曲線やプレイ結果により定着度が80pt未満になった単語の【暗記済み】フラグを取り外し、現在の定着度と再同期します。\n\n※80pt以上の暗記済み単語やお気に入り登録は維持されます。',
          style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('再同期を実行'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final count = await widget.database.syncMemorizedFlags();
        await _loadWords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                count > 0
                    ? '$count 件の単語の暗記フラグを解除・再同期しました'
                    : '暗記フラグの不整合はありませんでした（全件正常）',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('再同期中にエラーが発生しました: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading && _lastLoadedWordsVersion != widget.database.wordsDataVersion) {
      _refreshWordsSilent();
    }
  }

  Future<void> _initTts() async {
    await TtsService.instance.initialize();
  }

  Future<void> _speak(String text) async {
    await TtsService.instance.speak(text);
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    try {
      final currentVersion = widget.database.wordsDataVersion;
      final words = await widget.database.getAllWords();
      if (words.isEmpty) {
        await _rebuildDatabase(showSnackBar: false);
        return;
      }
      _lastLoadedWordsVersion = currentVersion;
      _allWords = words;
      _applyFilterAndGrouping();
    } catch (e) {
      debugPrint('Error loading words: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> refreshWords() async {
    await _refreshWordsSilent();
  }

  Future<void> _refreshWordsSilent() async {
    final currentVersion = widget.database.wordsDataVersion;
    final words = await widget.database.getAllWords();
    if (mounted) {
      setState(() {
        _lastLoadedWordsVersion = currentVersion;
        _allWords = words;
        _applyFilterAndGrouping();
      });
    }
  }

  /// 指定した条件を除外してフィルタリング（各ドロップダウンの候補リスト算出用）
  List<Word> _filterWordsExcept({
    bool skipCefr = false,
    bool skipChap = false,
    bool skipAz = false,
    bool skipCategory = false,
  }) {
    final query = _searchQuery.toLowerCase().trim();

    return _allWords.where((word) {
      if (query.isNotEmpty) {
        final matchesEng = word.english.toLowerCase().contains(query);
        final matchesJap = word.japanese.contains(query);
        if (!matchesEng && !matchesJap) return false;
      }
      if (_filterUnlearned && word.isMemorized) return false;
      if (_filterFavorite && !word.isFavorite) return false;

      if (!skipCefr && _selectedCefr != 'ALL') {
        final cleanCefr = word.cefr.toUpperCase().replaceAll('"', '').trim();
        if (cleanCefr != _selectedCefr) return false;
      }
      if (!skipChap && _selectedChap != 0 && word.chapter != _selectedChap) {
        return false;
      }
      if (!skipAz && _selectedAz != 'ALL') {
        final firstLetter = word.english.isNotEmpty ? word.english[0].toUpperCase() : '';
        if (firstLetter != _selectedAz) return false;
      }
      if (!skipCategory && _selectedCategory != 'ALL') {
        final cat = (word.category.isNotEmpty && word.category != 'General')
            ? word.category
            : 'General';
        if (cat != _selectedCategory) return false;
      }

      return true;
    }).toList();
  }

  /// フィルター＆ソートによるグルーピング計算
  void _applyFilterAndGrouping() {
    final filtered = _filterWordsExcept();
    _totalFilteredCount = filtered.length;

    final List<WordSection> sections = [];

    if (_sortMode == 'az') {
      filtered.sort((a, b) => a.english.toLowerCase().compareTo(b.english.toLowerCase()));
      final Map<String, List<Word>> map = {};
      for (final w in filtered) {
        final firstLetter = w.english.isNotEmpty ? w.english[0].toUpperCase() : '#';
        final key = RegExp(r'^[A-Z]$').hasMatch(firstLetter) ? firstLetter : '#';
        map.putIfAbsent(key, () => []).add(w);
      }
      final sortedKeys = map.keys.toList()..sort();
      for (final key in sortedKeys) {
        final list = map[key]!;
        final memorized = list.where((w) => w.isMemorized).length;
        sections.add(WordSection(
          key: key,
          title: key,
          words: list,
          memorizedCount: memorized,
        ));
      }
    } else if (_sortMode == 'category') {
      final Map<String, List<Word>> map = {};
      for (final w in filtered) {
        final cat = (w.category.isNotEmpty && w.category != 'General')
            ? w.category
            : 'General';
        map.putIfAbsent(cat, () => []).add(w);
      }
      final sortedKeys = map.keys.toList()..sort();
      for (final key in sortedKeys) {
        final list = map[key]!;
        final memorized = list.where((w) => w.isMemorized).length;
        sections.add(WordSection(
          key: key,
          title: key,
          words: list,
          memorizedCount: memorized,
        ));
      }
    } else {
      // Chap ソート (デフォルト)
      final Map<int, List<Word>> map = {};
      for (final w in filtered) {
        map.putIfAbsent(w.chapter, () => []).add(w);
      }
      final sortedKeys = map.keys.toList()..sort();
      for (final ch in sortedKeys) {
        final list = map[ch]!;
        final memorized = list.where((w) => w.isMemorized).length;
        sections.add(WordSection(
          key: 'ch_$ch',
          title: '$ch',
          words: list,
          memorizedCount: memorized,
        ));
      }
    }

    // 全単語マスターからチャプターごとの真の全体進捗（総数・80pt以上暗記数）を集計（フィルター非依存）
    final Map<int, ({int total, int memorized})> globalStats = {};
    for (final w in _allWords) {
      final current = globalStats[w.chapter];
      final isMem = w.retentionPoint >= 80;
      if (current == null) {
        globalStats[w.chapter] = (total: 1, memorized: isMem ? 1 : 0);
      } else {
        globalStats[w.chapter] = (
          total: current.total + 1,
          memorized: current.memorized + (isMem ? 1 : 0),
        );
      }
    }
    _chapterGlobalStats = globalStats;
    _sections = sections;
  }

  void _onFilterChanged({bool resetScroll = false}) {
    setState(() {
      _applyFilterAndGrouping();
    });
    if (resetScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _updateWordInPlace(Word updatedWord) {
    final index = _allWords.indexWhere((w) => w.id == updatedWord.id);
    final was80Plus = (index != -1) ? (_allWords[index].retentionPoint >= 80) : false;
    final is80Plus = updatedWord.retentionPoint >= 80;

    if (index != -1) {
      _allWords[index] = updatedWord;
    }

    // チャプターごとのグローバル80pt統計（キャラバナー用）をO(1)で同期更新
    final chap = updatedWord.chapter;
    if (_chapterGlobalStats.containsKey(chap) && (was80Plus != is80Plus)) {
      final currentStat = _chapterGlobalStats[chap]!;
      final diff = is80Plus ? 1 : -1;
      _chapterGlobalStats[chap] = (
        total: currentStat.total,
        memorized: (currentStat.memorized + diff).clamp(0, currentStat.total),
      );
    }

    // フィルター条件（お気に入りON / 未暗記ON）がある場合は一覧再構築
    if (_filterFavorite || _filterUnlearned) {
      _onFilterChanged();
      return;
    }

    // フィルター条件がない場合は、該当セクション内のリストのみ差し替えて再描画（3.1万件の再走査をスキップ）
    bool found = false;
    for (int i = 0; i < _sections.length; i++) {
      final sec = _sections[i];
      final wIndex = sec.words.indexWhere((w) => w.id == updatedWord.id);
      if (wIndex != -1) {
        final newWords = List<Word>.from(sec.words);
        newWords[wIndex] = updatedWord;
        final newMemCount = newWords.where((w) => w.isMemorized).length;
        _sections[i] = WordSection(
          key: sec.key,
          title: sec.title,
          subtitle: sec.subtitle,
          words: newWords,
          memorizedCount: newMemCount,
        );
        found = true;
        break;
      }
    }
    if (found) {
      setState(() {});
    } else {
      _onFilterChanged();
    }
  }

  Future<void> _toggleFavoriteFast(Word targetWord) async {
    final newStatus = !targetWord.isFavorite;
    final updated = targetWord.copyWith(isFavorite: newStatus);
    _updateWordInPlace(updated);
    await widget.database.toggleFavorite(targetWord.id, newStatus);
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // Skip the second quote in escaped pair ""
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  Future<void> _rebuildDatabase({bool showSnackBar = true}) async {
    setState(() => _isLoading = true);
    try {
      final csvString = await rootBundle.loadString('assets/words.csv');
      final lines = csvString.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) return;

      final rawHeader = _parseCsvLine(lines.first);
      final header = rawHeader.map((h) => h.replaceAll('"', '').trim()).toList();
      final List<Map<String, String>> rawData = [];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final values = _parseCsvLine(line);
        if (values.length >= header.length) {
          final map = <String, String>{};
          for (var j = 0; j < header.length; j++) {
            map[header[j]] = values[j];
          }
          rawData.add(map);
        }
      }

      await widget.database.clearAllWords();
      await widget.database.insertRawWords(rawData);
      final words = await widget.database.getAllWords();
      _allWords = words;
      _applyFilterAndGrouping();

      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DBの再構築が完了しました（全${_allWords.length}件）')),
        );
      }
    } catch (e) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _filterScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    BuddyService.instance.removeListener(_onBuddyChanged);
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showScrollToTop) ...[
            BouncyScaleTap(
              onTap: _scrollToPreviousSection,
              pressedScale: 0.90,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x25000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.keyboard_double_arrow_up_rounded, size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_sections.length > 1)
            BouncyScaleTap(
              onTap: _scrollToNextSection,
              pressedScale: 0.90,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x25000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.keyboard_double_arrow_down_rounded, size: 22, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryAccent))
          : SafeArea(
              child: CustomFastScrollbar(
                controller: _scrollController,
                topOffset: 164.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                    // 1. スリム検索・ソート・フィルターバー（上スクロール・引き下げ時に指の動きに追従して滑らかに出現するフローティングヘッダー）
                    SliverAppBar(
                      floating: true,
                      snap: false,
                      pinned: false,
                      automaticallyImplyLeading: false,
                      backgroundColor: _bgColor,
                      elevation: 0,
                      toolbarHeight: _activeFilterCount > 0 ? 155 : 128,
                      expandedHeight: _activeFilterCount > 0 ? 155 : 128,
                      collapsedHeight: _activeFilterCount > 0 ? 155 : 128,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: Container(
                          color: _bgColor,
                          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 検索バー（上部）
                              WordSearchBar(
                                searchController: _searchController,
                                searchFocusNode: _searchFocusNode,
                                onSubmitted: (val) {
                                  setState(() => _searchQuery = val.trim());
                                  _onFilterChanged(resetScroll: true);
                                },
                                onClear: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _onFilterChanged(resetScroll: true);
                                  _searchFocusNode.requestFocus();
                                },
                                activeFilterCount: _activeFilterCount,
                                onOpenFilter: _openFilterBottomSheet,
                                onSyncFlags: _showSyncMemorizedFlagsDialog,
                                onResetWordsDb: () async {
                                  await _rebuildDatabase();
                                },
                                onResetLearningData: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await widget.database.resetAllLearningData();
                                  await _loadWords();
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('学習データを初期化しました')),
                                  );
                                },
                                bgColor: _bgColor,
                                borderColor: _borderColor,
                                primaryColor: _primaryAccent,
                                textColor: _textPrimary,
                                textSecondaryColor: _textSecondary,
                              ),
                              const SizedBox(height: 6),

                              // ソート切替（Chap / A-Z / Cat.） ＆ 和訳常時トグルボタン ＆ スワイプ特訓ボタン
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8E2D5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          _buildSortButton('Chap', 'chap'),
                                          _buildSortButton('A-Z', 'az'),
                                          _buildSortButton('Cat.', 'category'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildToggleChip(
                                    label: _showJapanese ? '和訳: ON' : '和訳: OFF',
                                    isSelected: _showJapanese,
                                    accentColor: _primaryAccent,
                                    height: 30,
                                    onTap: () {
                                      setState(() => _showJapanese = !_showJapanese);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // スワイプ特訓ボタン（和訳ONと高さを完全に30pxで一致）
                                  BouncyScaleTap(
                                    onTap: () {
                                      final words = _sections.expand((s) => s.words).toList();
                                      final title = _hasActiveFilters
                                          ? '絞り込み特訓 ($_totalFilteredCount語)'
                                          : '全単語特訓 ($_totalFilteredCount語)';
                                      _startFlashcard(words, title);
                                    },
                                    child: Container(
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _primaryAccent.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _primaryAccent.withAlpha(80)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.style_rounded, size: 14, color: _primaryAccent),
                                          const SizedBox(width: 4),
                                          Text(
                                            'スワイプ特訓',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _primaryAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // アクティブフィルタータグ & 件数表示
                              _buildActiveFilterSummaryBar(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 2. セクションごとの吸い付き＆押し出しスライバーグループ
                    if (_sections.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            '該当する単語が見つかりません',
                            style: TextStyle(color: _textSecondary, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      for (final section in _sections)
                        SliverMainAxisGroup(
                          slivers: [
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: WordSectionStickyHeaderDelegate(
                                section: section,
                                sortMode: _sortMode,
                                bgColor: _bgColor,
                                borderColor: _borderColor,
                                primaryColor: _primaryAccent,
                                textColor: _textPrimary,
                                textSecondaryColor: _textSecondary,
                                onStartFlashcard: () => _startFlashcard(
                                  section.words,
                                  _sortMode == 'chap'
                                      ? 'Chapter ${section.title} 特訓'
                                      : '${section.title} 特訓',
                                ),
                              ),
                            ),
                            if (_sortMode == 'chap')
                              SliverToBoxAdapter(
                                child: Builder(
                                  builder: (context) {
                                    final chapNum = int.tryParse(section.title.replaceAll(RegExp(r'[^0-9]'), '')) ??
                                        int.tryParse(section.key.replaceAll(RegExp(r'[^0-9]'), '')) ??
                                        1;
                                    final stats = _chapterGlobalStats[chapNum];
                                    return WordChapterBanner(
                                      section: section,
                                      totalChapterWords: stats?.total,
                                      memorizedChapterWords: stats?.memorized,
                                    );
                                  },
                                ),
                              ),
                            SliverFixedExtentList(
                              itemExtent: 120.0,
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final word = section.words[index];
                                  final isKeyboardActive = _searchFocusNode.hasFocus || (MediaQuery.of(context).viewInsets.bottom > 0);
                                  return WordCardTile(
                                    word: word,
                                    showJapanese: _showJapanese,
                                    isKeyboardActive: isKeyboardActive,
                                    onSpeak: () => _speak(word.english),
                                    onToggleFavorite: () => _toggleFavoriteFast(word),
                                    onTap: () {
                                      final isKbActive = _searchFocusNode.hasFocus || (MediaQuery.of(context).viewInsets.bottom > 0);
                                      if (isKbActive) {
                                        _searchFocusNode.unfocus();
                                        FocusScope.of(context).unfocus();
                                        return;
                                      }
                                      final allCurrent = _sections.expand((s) => s.words).toList();
                                      final gIdx = allCurrent.indexWhere((w) => w.id == word.id);
                                      WordDetailModal.show(
                                        context: context,
                                        wordList: allCurrent,
                                        initialIndex: gIdx >= 0 ? gIdx : 0,
                                        database: widget.database,
                                        onFavoriteChanged: () => _loadWords(),
                                      );
                                    },
                                    onDoubleTap: () {
                                      final isKbActive = _searchFocusNode.hasFocus || (MediaQuery.of(context).viewInsets.bottom > 0);
                                      if (isKbActive) {
                                        _searchFocusNode.unfocus();
                                        FocusScope.of(context).unfocus();
                                        return;
                                      }
                                      final allCurrent = _sections.expand((s) => s.words).toList();
                                      final gIdx = allCurrent.indexWhere((w) => w.id == word.id);
                                      WordDetailModal.show(
                                        context: context,
                                        wordList: allCurrent,
                                        initialIndex: gIdx >= 0 ? gIdx : 0,
                                        database: widget.database,
                                        onFavoriteChanged: () => _loadWords(),
                                      );
                                    },
                                    onSwipeRight: () async {
                                      await widget.database.markAsMemorizedManual(word.id);
                                      final updated = word.copyWith(
                                        retentionPoint: 80,
                                        pointDecreasedTotal: 0,
                                        isMemorized: true,
                                        isRestricted: false,
                                      );
                                      _updateWordInPlace(updated);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('「${word.english}」を暗記済みに設定しました（制限解除）'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                    onSwipeLeft: () async {
                                      await widget.database.resetRetentionManual(word.id);
                                      final updated = word.copyWith(
                                        retentionPoint: 0,
                                        isMemorized: false,
                                        isRestricted: true,
                                      );
                                      _updateWordInPlace(updated);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('「${word.english}」の定着度を0ptにリセットしました'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                                childCount: section.words.length,
                              ),
                            ),
                          ],
                        ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSortButton(String label, String modeKey) {
    final isSelected = _sortMode == modeKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _sortMode = modeKey;
          _onFilterChanged(resetScroll: true);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? _primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isSelected,
    Color? accentColor,
    double height = 30,
    required VoidCallback onTap,
  }) {
    final color = accentColor ?? _secondaryAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : _cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : _borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: height > 30 ? 12 : 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _filterUnlearned ||
      _filterFavorite ||
      _selectedCefr != 'ALL' ||
      _selectedChap != 0 ||
      _selectedAz != 'ALL' ||
      _selectedCategory != 'ALL';

  int get _activeFilterCount {
    int count = 0;
    if (_filterUnlearned) count++;
    if (_filterFavorite) count++;
    if (_selectedCefr != 'ALL') count++;
    if (_selectedChap != 0) count++;
    if (_selectedAz != 'ALL') count++;
    if (_selectedCategory != 'ALL') count++;
    return count;
  }

  void _openFilterBottomSheet() {
    final availableCefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final availableChapters = _allWords.map((w) => w.chapter).toSet().toList()..sort();
    final Map<String, List<int>> cefrToChapters = {};
    for (final cefr in availableCefr) {
      final chaps = _allWords
          .where((w) => w.cefr.toUpperCase().trim() == cefr)
          .map((w) => w.chapter)
          .toSet()
          .toList()
        ..sort();
      cefrToChapters[cefr] = chaps;
    }
    final availableAz = _allWords
        .where((w) => w.english.isNotEmpty && RegExp(r'^[A-Za-z]').hasMatch(w.english[0]))
        .map((w) => w.english[0].toUpperCase())
        .toSet()
        .toList()
      ..sort();
    final availableCategories = _allWords
        .map((w) => (w.category.isNotEmpty && w.category != 'General') ? w.category : 'General')
        .toSet()
        .toList()
      ..sort();

    final currentState = WordFilterState(
      filterUnlearned: _filterUnlearned,
      filterFavorite: _filterFavorite,
      selectedCefr: _selectedCefr,
      selectedChapter: _selectedChap == 0 ? 'ALL' : _selectedChap.toString(),
      selectedAz: _selectedAz,
      selectedCategory: _selectedCategory,
    );

    WordFilterBottomSheet.show(
      context: context,
      initialFilter: currentState,
      sortMode: _sortMode,
      availableCefr: availableCefr,
      availableChapters: availableChapters,
      cefrToChapters: cefrToChapters,
      availableAz: availableAz,
      availableCategories: availableCategories,
      onApply: (newState) {
        _filterUnlearned = newState.filterUnlearned;
        _filterFavorite = newState.filterFavorite;
        _selectedCefr = newState.selectedCefr;
        _selectedChap = newState.selectedChapter == 'ALL' ? 0 : int.tryParse(newState.selectedChapter) ?? 0;
        _selectedAz = newState.selectedAz;
        _selectedCategory = newState.selectedCategory;
        _onFilterChanged(resetScroll: true);
      },
    );
  }

  Widget _buildActiveFilterSummaryBar() {
    if (!_hasActiveFilters) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '表示中: $_totalFilteredCount 件',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: _textSecondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            '$_totalFilteredCount件 ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: _textSecondary,
            ),
          ),
          if (_filterUnlearned) ...[
            _buildActiveTag('未暗記', () { _filterUnlearned = false; _onFilterChanged(resetScroll: true); }),
            const SizedBox(width: 4),
          ],
          if (_filterFavorite) ...[
            _buildActiveTag('お気に入り', () { _filterFavorite = false; _onFilterChanged(resetScroll: true); }),
            const SizedBox(width: 4),
          ],
          if (_selectedCefr != 'ALL') ...[
            _buildActiveTag('CEFR: $_selectedCefr', () { _selectedCefr = 'ALL'; _onFilterChanged(resetScroll: true); }),
            const SizedBox(width: 4),
          ],
          if (_selectedChap != 0) ...[
            _buildActiveTag('Ch.$_selectedChap', () { _selectedChap = 0; _onFilterChanged(resetScroll: true); }),
            const SizedBox(width: 4),
          ],
          if (_selectedAz != 'ALL') ...[
            _buildActiveTag('A-Z: $_selectedAz', () { _selectedAz = 'ALL'; _onFilterChanged(resetScroll: true); }),
            const SizedBox(width: 4),
          ],
          if (_selectedCategory != 'ALL') ...[
            _buildActiveTag('Cat: $_selectedCategory', () { _selectedCategory = 'ALL'; _onFilterChanged(resetScroll: true); }),
            const SizedBox(width: 4),
          ],
          InkWell(
            onTap: () {
              _filterUnlearned = false;
              _filterFavorite = false;
              _selectedCefr = 'ALL';
              _selectedChap = 0;
              _selectedAz = 'ALL';
              _selectedCategory = 'ALL';
              _onFilterChanged(resetScroll: true);
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '全解除',
                style: TextStyle(fontSize: 11, color: _secondaryAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 4, 2),
      decoration: BoxDecoration(
        color: _primaryAccent.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _primaryAccent.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryAccent),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: _primaryAccent),
          ),
        ],
      ),
    );
  }
}

