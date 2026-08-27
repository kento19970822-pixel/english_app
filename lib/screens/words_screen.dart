// コード管理番号: VER-20260826-08
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';
import '../widgets/custom_fast_scrollbar.dart';
import '../widgets/pixel_character_widget.dart';
import '../widgets/sticky_section_header.dart';
import '../widgets/word_card_tile.dart';
import '../widgets/word_detail_modal.dart';
import '../widgets/word_filter_bottom_sheet.dart';

/// 単語セクションデータクラス
class WordSection {
  final String key;
  final String title;
  final String? subtitle;
  final List<Word> words;
  final int memorizedCount;

  const WordSection({
    required this.key,
    required this.title,
    this.subtitle,
    required this.words,
    required this.memorizedCount,
  });
}

class _SectionStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WordSection section;
  final String sortMode;

  _SectionStickyHeaderDelegate({
    required this.section,
    required this.sortMode,
  });

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return StickySectionHeader(
      title: section.title,
      subtitle: section.subtitle,
      totalCount: section.words.length,
      memorizedCount: section.memorizedCount,
      sortMode: sortMode,
    );
  }

  @override
  bool shouldRebuild(covariant _SectionStickyHeaderDelegate oldDelegate) {
    return oldDelegate.section != section || oldDelegate.sortMode != sortMode;
  }
}

class WordsScreen extends StatefulWidget {
  final AppDatabase database;

  const WordsScreen({super.key, required this.database});

  @override
  State<WordsScreen> createState() => WordsScreenState();
}

class WordsScreenState extends State<WordsScreen> {
  List<Word> _allWords = [];
  List<WordSection> _sections = [];
  int _totalFilteredCount = 0;

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

  // パステルテーマカラー
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

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
        title: const Row(
          children: [
            Icon(Icons.published_with_changes_rounded, color: _primaryAccent, size: 24),
            SizedBox(width: 8),
            Text(
              '暗記フラグの再同期',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
            ),
          ],
        ),
        content: const Text(
          '忘却曲線やプレイ結果により定着度が80pt未満になった単語の【暗記済み】フラグを取り外し、現在の定着度と再同期します。\n\n※80pt以上の暗記済み単語やお気に入り登録は維持されます。',
          style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('再同期を実行'),
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
    if (!_isLoading) {
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
      final words = await widget.database.getAllWords();
      if (words.isEmpty) {
        await _rebuildDatabase(showSnackBar: false);
        return;
      }
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
    final words = await widget.database.getAllWords();
    if (mounted) {
      setState(() {
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
          title: 'Chapter $ch',
          words: list,
          memorizedCount: memorized,
        ));
      }
    }

    _sections = sections;
  }

  void _onFilterChanged() {
    setState(() {
      _applyFilterAndGrouping();
    });
  }

  void _updateWordInPlace(Word updatedWord) {
    final index = _allWords.indexWhere((w) => w.id == updatedWord.id);
    if (index != -1) {
      _allWords[index] = updatedWord;
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
        final newMemCount = newWords.where((w) => w.isMemorized || w.retentionPoint >= 80).length;
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
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: _primaryAccent,
              foregroundColor: Colors.white,
              elevation: 3,
              tooltip: '最上部へスクロール',
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryAccent))
          : SafeArea(
              child: CustomFastScrollbar(
                controller: _scrollController,
                topOffset: 164.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                    // 1. スリム検索・ソート・フィルターバー（自動伸縮でオーバーフロー防止）
                    SliverToBoxAdapter(
                      child: Container(
                        color: _bgColor,
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 6.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 検索バー ＆ 効果音 ＆ 絞り込みボタン ＆ その他データ管理メニュー
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFEAE0),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _borderColor),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      textAlignVertical: TextAlignVertical.center,
                                      textInputAction: TextInputAction.search,
                                      decoration: InputDecoration(
                                        hintText: '英単語または和訳で検索...',
                                        hintStyle: const TextStyle(fontSize: 13, color: _textSecondary),
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.search_rounded, size: 20, color: _textSecondary),
                                          onPressed: () {
                                            setState(() => _searchQuery = _searchController.text.trim());
                                            _onFilterChanged();
                                            FocusScope.of(context).unfocus();
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.cancel_rounded, size: 18, color: _textSecondary),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() => _searchQuery = '');
                                                  _onFilterChanged();
                                                  _searchFocusNode.requestFocus();
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                      ),
                                      style: const TextStyle(fontSize: 14, color: _textPrimary),
                                      onSubmitted: (val) {
                                        setState(() => _searchQuery = val.trim());
                                        _onFilterChanged();
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ListenableBuilder(
                                  listenable: SoundService.instance,
                                  builder: (context, _) {
                                    final seOn = SoundService.instance.isSeEnabled;
                                    return IconButton(
                                      icon: Icon(
                                        seOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                        color: seOn ? _primaryAccent : _textSecondary.withAlpha(150),
                                        size: 22,
                                      ),
                                      tooltip: seOn ? '効果音: ON' : '効果音: OFF',
                                      onPressed: () {
                                        SoundService.instance.setSeEnabled(!seOn);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                    );
                                  },
                                ),
                                // 絞り込みフィルターボタン
                                Badge(
                                  isLabelVisible: _hasActiveFilters,
                                  label: Text('$_activeFilterCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  backgroundColor: _primaryAccent,
                                  offset: const Offset(-2, 2),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.tune_rounded,
                                      color: _hasActiveFilters ? _primaryAccent : _textSecondary,
                                      size: 22,
                                    ),
                                    tooltip: '絞り込みフィルター',
                                    onPressed: _openFilterBottomSheet,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                  ),
                                ),
                                // その他メニュー（DB再同期・再構築）
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: _textSecondary, size: 22),
                                  tooltip: 'その他・データ管理',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
                                  onSelected: (val) {
                                    if (val == 'sync_flags') {
                                      _showSyncMemorizedFlagsDialog();
                                    } else if (val == 'rebuild_db') {
                                      _rebuildDatabase();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'sync_flags',
                                      child: Row(
                                        children: [
                                          Icon(Icons.published_with_changes_rounded, size: 18, color: _primaryAccent),
                                          SizedBox(width: 8),
                                          Text('暗記フラグ再同期 (80pt未満解除)', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'rebuild_db',
                                      child: Row(
                                        children: [
                                          Icon(Icons.sync_rounded, size: 18, color: _secondaryAccent),
                                          SizedBox(width: 8),
                                          Text('DB完全再構築 (CSVデータ再読み込み)', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // ソート切替（Chap / A-Z / Cat.） ＆ 和訳常時トグルボタン
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
                              ],
                            ),
                            const SizedBox(height: 4),

                            // アクティブフィルタータグ & 件数表示
                            _buildActiveFilterSummaryBar(),
                          ],
                        ),
                      ),
                    ),

                    // 2. セクションごとの吸い付き＆押し出しスライバーグループ
                    if (_sections.isEmpty)
                      const SliverFillRemaining(
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
                              delegate: _SectionStickyHeaderDelegate(
                                section: section,
                                sortMode: _sortMode,
                              ),
                            ),
                            if (_sortMode == 'chap')
                              SliverToBoxAdapter(
                                child: _buildChapterCharacterBanner(section),
                              ),
                            SliverFixedExtentList(
                              itemExtent: 74.0,
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final word = section.words[index];
                                  return WordCardTile(
                                    word: word,
                                    showJapanese: _showJapanese,
                                    onSpeak: () => _speak(word.english),
                                    onToggleFavorite: () => _toggleFavoriteFast(word),
                                    onTap: () {
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

  Widget _buildChapterCharacterBanner(WordSection section) {
    if (section.words.isEmpty) return const SizedBox.shrink();
    final chapter = section.words.first.chapter;
    final speciesIndex = chapter - 1;
    final species = getCharacterSpecies(chapter);

    // フィルター状態に関わらず、チャプター全体の全単語を基準に暗記率（80pt以上基準）と成長段階を算出
    final chapterAllWords = _allWords.where((w) => w.chapter == chapter).toList();
    final int totalWordsInChapter = chapterAllWords.isNotEmpty ? chapterAllWords.length : section.words.length;
    final int memorizedCount = chapterAllWords.where((w) => w.isMemorized || w.retentionPoint >= 80).length;
    final double rate = totalWordsInChapter > 0 ? (memorizedCount / totalWordsInChapter) * 100.0 : 0.0;
    final growthState = PixelCharacterWidget.stateFromRate(rate, true);
    final isCleared = rate >= 80.0;
    final isLocked = growthState == CharacterGrowthState.locked;

    // 要件9: 1段へ統合表示「元気 52%（52/100）」
    String statusText;
    Color statusColor;
    if (isLocked || rate <= 0) {
      statusText = '🔒 未学習 0% (0/$totalWordsInChapter)';
      statusColor = _textSecondary;
    } else if (isCleared) {
      statusText = '🌟 進化 ${rate.toInt()}% ($memorizedCount/$totalWordsInChapter)';
      statusColor = const Color(0xFF6A1B9A);
    } else if (rate >= 50.0) {
      statusText = '😊 元気 ${rate.toInt()}% ($memorizedCount/$totalWordsInChapter)';
      statusColor = Colors.green.shade700;
    } else {
      statusText = '🥀 元気ない ${rate.toInt()}% ($memorizedCount/$totalWordsInChapter)';
      statusColor = Colors.deepOrange;
    }

    final isCurrentBuddy = (speciesIndex == BuddyService.instance.selectedSpeciesId);
    final favStamp = isCurrentBuddy ? BuddyService.instance.favoriteStamp : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          PixelCharacterWidget(
            speciesIndex: speciesIndex,
            growthState: growthState,
            actionState: isCleared ? CharacterActionState.walk : CharacterActionState.idle,
            favoriteStamp: favStamp,
            size: 42,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Ch.$chapter: ${isLocked ? '？？？？？' : species.japaneseName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? _textSecondary : _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      species.category.icon,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (rate / 100.0).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFEFEAE0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCleared ? const Color(0xFF8E24AA) : _primaryAccent,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, String modeKey) {
    final isSelected = _sortMode == modeKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _sortMode = modeKey;
            _applyFilterAndGrouping();
          });
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
        setState(() {
          _filterUnlearned = newState.filterUnlearned;
          _filterFavorite = newState.filterFavorite;
          _selectedCefr = newState.selectedCefr;
          _selectedChap = newState.selectedChapter == 'ALL' ? 0 : int.tryParse(newState.selectedChapter) ?? 0;
          _selectedAz = newState.selectedAz;
          _selectedCategory = newState.selectedCategory;
          _applyFilterAndGrouping();
        });
      },
    );
  }

  Widget _buildActiveFilterSummaryBar() {
    if (!_hasActiveFilters) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '表示中: $_totalFilteredCount 件',
          style: const TextStyle(
            fontSize: 11,
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _textSecondary,
            ),
          ),
          if (_filterUnlearned) ...[
            _buildActiveTag('未暗記', () => setState(() { _filterUnlearned = false; _applyFilterAndGrouping(); })),
            const SizedBox(width: 4),
          ],
          if (_filterFavorite) ...[
            _buildActiveTag('お気に入り', () => setState(() { _filterFavorite = false; _applyFilterAndGrouping(); })),
            const SizedBox(width: 4),
          ],
          if (_selectedCefr != 'ALL') ...[
            _buildActiveTag('CEFR: $_selectedCefr', () => setState(() { _selectedCefr = 'ALL'; _applyFilterAndGrouping(); })),
            const SizedBox(width: 4),
          ],
          if (_selectedChap != 0) ...[
            _buildActiveTag('Ch.$_selectedChap', () => setState(() { _selectedChap = 0; _applyFilterAndGrouping(); })),
            const SizedBox(width: 4),
          ],
          if (_selectedAz != 'ALL') ...[
            _buildActiveTag('A-Z: $_selectedAz', () => setState(() { _selectedAz = 'ALL'; _applyFilterAndGrouping(); })),
            const SizedBox(width: 4),
          ],
          if (_selectedCategory != 'ALL') ...[
            _buildActiveTag('Cat: $_selectedCategory', () => setState(() { _selectedCategory = 'ALL'; _applyFilterAndGrouping(); })),
            const SizedBox(width: 4),
          ],
          InkWell(
            onTap: () {
              setState(() {
                _filterUnlearned = false;
                _filterFavorite = false;
                _selectedCefr = 'ALL';
                _selectedChap = 0;
                _selectedAz = 'ALL';
                _selectedCategory = 'ALL';
                _applyFilterAndGrouping();
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryAccent),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: _primaryAccent),
          ),
        ],
      ),
    );
  }
}
