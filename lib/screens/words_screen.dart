// コード管理番号: VER-20260826-08
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../services/tts_service.dart';
import '../widgets/custom_fast_scrollbar.dart';
import '../widgets/pixel_character_widget.dart';
import '../widgets/sticky_section_header.dart';
import '../widgets/word_card_tile.dart';

enum WordListItemType { header, banner, card }

class WordListItem {
  final WordListItemType type;
  final WordSection? section;
  final Word? word;

  const WordListItem.header(this.section)
      : type = WordListItemType.header,
        word = null;

  const WordListItem.banner(this.section)
      : type = WordListItemType.banner,
        word = null;

  const WordListItem.card(this.word, this.section)
      : type = WordListItemType.card;
}

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

class _SectionOffsetRange {
  final WordSection section;
  final double startOffset;
  final double endOffset;
  final double nextHeaderOffset;

  const _SectionOffsetRange({
    required this.section,
    required this.startOffset,
    required this.endOffset,
    required this.nextHeaderOffset,
  });
}

class _StickyHeaderState {
  final WordSection currentSection;
  final double pushOffset;

  const _StickyHeaderState({
    required this.currentSection,
    required this.pushOffset,
  });
}

class _SingleStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ValueNotifier<_StickyHeaderState?> stickyNotifier;
  final String sortMode;
  final WordSection defaultSection;

  _SingleStickyHeaderDelegate({
    required this.stickyNotifier,
    required this.sortMode,
    required this.defaultSection,
  });

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ValueListenableBuilder<_StickyHeaderState?>(
      valueListenable: stickyNotifier,
      builder: (context, state, _) {
        final current = state?.currentSection ?? defaultSection;
        final pushOffset = state?.pushOffset ?? 0.0;

        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, pushOffset),
            child: StickySectionHeader(
              title: current.title,
              subtitle: current.subtitle,
              totalCount: current.words.length,
              memorizedCount: current.memorizedCount,
              sortMode: sortMode,
            ),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(covariant _SingleStickyHeaderDelegate oldDelegate) {
    return oldDelegate.sortMode != sortMode ||
        oldDelegate.defaultSection != defaultSection;
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
  List<WordListItem> _flatListItems = [];
  List<_SectionOffsetRange> _sectionOffsetRanges = [];
  final ValueNotifier<_StickyHeaderState?> _stickyHeaderNotifier = ValueNotifier(null);
  WordSection? _firstSection;
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
    _updateStickyHeader();
  }

  void _updateStickyHeader() {
    if (!_scrollController.hasClients || _sectionOffsetRanges.isEmpty) {
      if (_firstSection != null) {
        _stickyHeaderNotifier.value = _StickyHeaderState(
          currentSection: _firstSection!,
          pushOffset: 0.0,
        );
      } else {
        _stickyHeaderNotifier.value = null;
      }
      return;
    }
    const double appBarHeight = 154.0;
    final sliverOffset = (_scrollController.offset - appBarHeight).clamp(0.0, double.infinity);

    // Binary search for active section range in the sliver list
    int low = 0;
    int high = _sectionOffsetRanges.length - 1;
    _SectionOffsetRange? matched;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final range = _sectionOffsetRanges[mid];
      if (sliverOffset >= range.startOffset && sliverOffset < range.endOffset) {
        matched = range;
        break;
      } else if (sliverOffset < range.startOffset) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    if (matched != null) {
      final distanceToNext = matched.nextHeaderOffset - sliverOffset;
      final pushOffset = (distanceToNext < 48.0) ? (distanceToNext - 48.0) : 0.0;
      _stickyHeaderNotifier.value = _StickyHeaderState(
        currentSection: matched.section,
        pushOffset: pushOffset,
      );
    } else if (_firstSection != null) {
      _stickyHeaderNotifier.value = _StickyHeaderState(
        currentSection: _firstSection!,
        pushOffset: 0.0,
      );
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

    final List<WordListItem> flatItems = [];
    final List<_SectionOffsetRange> ranges = [];
    double currentOffset = 0.0;

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sectionStart = currentOffset;

      // セクション0は常時上部に固定表示されるためリスト内ヘッダーを省略（二重表示の完全防止）
      // セクション1以降はリスト内にヘッダーを配置し、上部バーを押し出すアニメーションを実現
      if (i > 0) {
        flatItems.add(WordListItem.header(section));
        currentOffset += 48.0;
      }

      if (_sortMode == 'chap') {
        flatItems.add(WordListItem.banner(section));
        currentOffset += 82.0;
      }

      for (final w in section.words) {
        flatItems.add(WordListItem.card(w, section));
        currentOffset += 196.0;
      }

      final sectionEnd = currentOffset;
      final nextHeaderStart = (i < sections.length - 1) ? sectionEnd : double.infinity;
      ranges.add(_SectionOffsetRange(
        section: section,
        startOffset: sectionStart,
        endOffset: sectionEnd,
        nextHeaderOffset: nextHeaderStart,
      ));
    }

    _flatListItems = flatItems;
    _sectionOffsetRanges = ranges;
    _firstSection = sections.isNotEmpty ? sections.first : null;
    _updateStickyHeader();
  }

  void _onFilterChanged() {
    setState(() {
      _applyFilterAndGrouping();
    });
  }

  Future<void> _toggleFavoriteFast(Word targetWord) async {
    final newStatus = !targetWord.isFavorite;
    final index = _allWords.indexWhere((w) => w.id == targetWord.id);
    if (index != -1) {
      _allWords[index] = _allWords[index].copyWith(isFavorite: newStatus);
    }
    _onFilterChanged();
    await widget.database.toggleFavorite(targetWord.id, newStatus);
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
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
        final values = _parseCsvLine(line).map((v) => v.replaceAll('"', '').trim()).toList();
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
    _stickyHeaderNotifier.dispose();
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
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                  // 1. スクロールで出入りする可変ヘッダー
                  SliverAppBar(
                    floating: true,
                    snap: false,
                    pinned: false,
                    backgroundColor: _bgColor,
                    elevation: 0,
                    toolbarHeight: 0,
                    collapsedHeight: 0,
                    expandedHeight: 154,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: 154,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 6.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 検索バー ＆ 暗記リセット ＆ DBリフレッシュ
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
                                          textAlignVertical: TextAlignVertical.center,
                                          decoration: InputDecoration(
                                            hintText: '英単語または和訳で検索...',
                                            hintStyle: const TextStyle(fontSize: 13, color: _textSecondary),
                                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _textSecondary),
                                            suffixIcon: _searchController.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.cancel_rounded, size: 18, color: _textSecondary),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      setState(() => _searchQuery = '');
                                                      _onFilterChanged();
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
                                          onChanged: (val) {
                                            setState(() => _searchQuery = val);
                                            _onFilterChanged();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.published_with_changes_rounded, color: _primaryAccent),
                                      tooltip: '暗記フラグ再同期（80pt未満を解除）',
                                      onPressed: _isLoading ? null : _showSyncMemorizedFlagsDialog,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                    ),
                                    const SizedBox(width: 2),
                                    IconButton(
                                      icon: const Icon(Icons.sync_rounded, color: _primaryAccent),
                                      tooltip: 'DB完全再構築',
                                      onPressed: _isLoading ? null : _rebuildDatabase,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // ソート切替（Chap / A-Z / Cat.） ＆ 和訳常時トグルボタン
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFEAE0),
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
                                    // 和訳トグルボタン（常時アクセス可能・スクロール不要）
                                    _buildToggleChip(
                                      label: _showJapanese ? '和訳: ON' : '和訳: OFF',
                                      isSelected: _showJapanese,
                                      accentColor: _primaryAccent,
                                      height: 32,
                                      onTap: () {
                                        setState(() => _showJapanese = !_showJapanese);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // フィルタータグ（横スクロール対応）
                                SingleChildScrollView(
                                  controller: _filterScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      // 未暗記トグル
                                      _buildToggleChip(
                                        label: '未暗記',
                                        isSelected: _filterUnlearned,
                                        onTap: () {
                                          setState(() {
                                            _filterUnlearned = !_filterUnlearned;
                                            _applyFilterAndGrouping();
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),

                                      // お気に入りトグル
                                      _buildToggleChip(
                                        label: 'お気に入り ★',
                                        isSelected: _filterFavorite,
                                        onTap: () {
                                          setState(() {
                                            _filterFavorite = !_filterFavorite;
                                            _applyFilterAndGrouping();
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),

                                      // CEFRドロップダウン（現在条件に連動）
                                      _buildCefrDropdown(),
                                      const SizedBox(width: 6),

                                      // Chapドロップダウン（現在条件に連動）
                                      _buildChapDropdown(),
                                      const SizedBox(width: 6),

                                      // A-Zドロップダウン（現在条件に連動）
                                      _buildAzDropdown(),
                                      const SizedBox(width: 6),

                                      // Categoryドロップダウン（現在条件に連動）
                                      _buildCategoryDropdown(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // 表示件数
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '表示中: $_totalFilteredCount 件',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. 吸い付きスティッキーヘッダー（検索バー直下に自動配置され位置重複ゼロ）
                  if (_firstSection != null)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SingleStickyHeaderDelegate(
                        stickyNotifier: _stickyHeaderNotifier,
                        sortMode: _sortMode,
                        defaultSection: _firstSection!,
                      ),
                    ),

                  // 3. 単語リスト（フラット仮想化リストによる超高速描画）
                  if (_flatListItems.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          '該当する単語が見つかりません',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    SliverVariedExtentList.builder(
                      itemCount: _flatListItems.length,
                      itemExtentBuilder: (index, _) => _calculateItemExtent(index),
                      itemBuilder: (context, index) {
                        final item = _flatListItems[index];
                        switch (item.type) {
                          case WordListItemType.header:
                            final section = item.section!;
                            return StickySectionHeader(
                                title: section.title,
                                subtitle: section.subtitle,
                                totalCount: section.words.length,
                                memorizedCount: section.memorizedCount,
                                sortMode: _sortMode,
                              );
                            case WordListItemType.banner:
                              return _buildChapterCharacterBanner(item.section!);
                            case WordListItemType.card:
                              final word = item.word!;
                              return WordCardTile(
                                word: word,
                                showJapanese: _showJapanese,
                                onSpeak: () => _speak(word.english),
                                onToggleFavorite: () => _toggleFavoriteFast(word),
                                onSwipeRight: () async {
                                  await widget.database.markAsMemorizedManual(word.id);
                                  final idx = _allWords.indexWhere((w) => w.id == word.id);
                                  if (idx != -1) {
                                    _allWords[idx] = _allWords[idx].copyWith(
                                      retentionPoint: 80,
                                      isMemorized: true,
                                      isRestricted: false,
                                    );
                                    _onFilterChanged();
                                  }
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
                                  final idx = _allWords.indexWhere((w) => w.id == word.id);
                                  if (idx != -1) {
                                    _allWords[idx] = _allWords[idx].copyWith(
                                      retentionPoint: 0,
                                      isMemorized: false,
                                      isRestricted: true,
                                    );
                                    _onFilterChanged();
                                  }
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
                          }
                        },
                      ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  double _calculateItemExtent(int index) {
    if (index >= _flatListItems.length) return 196.0;
    switch (_flatListItems[index].type) {
      case WordListItemType.header:
        return 48.0;
      case WordListItemType.banner:
        return 82.0;
      case WordListItemType.card:
        return 196.0;
    }
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

  Widget _buildCefrDropdown() {
    final isActive = _selectedCefr != 'ALL';
    final candidateWords = _filterWordsExcept(skipCefr: true);

    // 各CEFRごとの該当件数を集計
    final Map<String, int> counts = {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0};
    for (final w in candidateWords) {
      final cefr = w.cefr.toUpperCase().replaceAll('"', '').trim();
      if (counts.containsKey(cefr)) {
        counts[cefr] = counts[cefr]! + 1;
      }
    }

    final totalCandidates = candidateWords.length;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isActive ? _secondaryAccent.withAlpha(40) : _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? _secondaryAccent : _borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCefr,
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          items: [
            DropdownMenuItem(value: 'ALL', child: Text('CEFR: 全て ($totalCandidates)')),
            ...counts.entries
                .where((e) => e.value > 0 || e.key == _selectedCefr)
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text('CEFR: ${e.key} (${e.value})'),
                  ),
                ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCefr = val;
                _applyFilterAndGrouping();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildChapDropdown() {
    final isActive = _selectedChap != 0;
    final candidateWords = _filterWordsExcept(skipChap: true);

    // 各Chapごとの該当件数を集計
    final Map<int, int> counts = {};
    for (final w in candidateWords) {
      counts[w.chapter] = (counts[w.chapter] ?? 0) + 1;
    }

    final sortedChaps = counts.keys.toList()..sort();
    // 現在選択中のChapが含まれていなければ追加
    if (_selectedChap != 0 && !counts.containsKey(_selectedChap)) {
      sortedChaps.add(_selectedChap);
      counts[_selectedChap] = 0;
      sortedChaps.sort();
    }

    final totalCandidates = candidateWords.length;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isActive ? _secondaryAccent.withAlpha(40) : _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? _secondaryAccent : _borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedChap,
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          items: [
            DropdownMenuItem(value: 0, child: Text('Chap: 全て ($totalCandidates)')),
            ...sortedChaps.map(
              (ch) => DropdownMenuItem(
                value: ch,
                child: Text('Ch. $ch (${counts[ch] ?? 0})'),
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedChap = val;
                _applyFilterAndGrouping();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAzDropdown() {
    final isActive = _selectedAz != 'ALL';
    final candidateWords = _filterWordsExcept(skipAz: true);

    // 各A-Zごとの該当件数を集計
    final Map<String, int> counts = {};
    for (final w in candidateWords) {
      if (w.english.isNotEmpty) {
        final firstLetter = w.english[0].toUpperCase();
        if (RegExp(r'^[A-Z]$').hasMatch(firstLetter)) {
          counts[firstLetter] = (counts[firstLetter] ?? 0) + 1;
        }
      }
    }

    final sortedAz = counts.keys.toList()..sort();
    if (_selectedAz != 'ALL' && !counts.containsKey(_selectedAz)) {
      sortedAz.add(_selectedAz);
      counts[_selectedAz] = 0;
      sortedAz.sort();
    }

    final totalCandidates = candidateWords.length;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isActive ? _secondaryAccent.withAlpha(40) : _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? _secondaryAccent : _borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAz,
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          items: [
            DropdownMenuItem(value: 'ALL', child: Text('A-Z: 全て ($totalCandidates)')),
            ...sortedAz.map(
              (letter) => DropdownMenuItem(
                value: letter,
                child: Text('A-Z: $letter (${counts[letter] ?? 0})'),
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedAz = val;
                _applyFilterAndGrouping();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final isActive = _selectedCategory != 'ALL';
    final candidateWords = _filterWordsExcept(skipCategory: true);

    // 各Categoryごとの該当件数を集計
    final Map<String, int> counts = {};
    for (final w in candidateWords) {
      final cat = (w.category.isNotEmpty && w.category != 'General')
          ? w.category
          : 'General';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    final sortedCats = counts.keys.toList()..sort();
    if (_selectedCategory != 'ALL' && !counts.containsKey(_selectedCategory)) {
      sortedCats.add(_selectedCategory);
      counts[_selectedCategory] = 0;
      sortedCats.sort();
    }

    final totalCandidates = candidateWords.length;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isActive ? _secondaryAccent.withAlpha(40) : _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? _secondaryAccent : _borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: isActive ? _secondaryAccent : _textSecondary,
          ),
          items: [
            DropdownMenuItem(value: 'ALL', child: Text('Category: 全て ($totalCandidates)')),
            ...sortedCats.map(
              (cat) => DropdownMenuItem(
                value: cat,
                child: Text('$cat (${counts[cat] ?? 0})'),
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCategory = val;
                _applyFilterAndGrouping();
              });
            }
          },
        ),
      ),
    );
  }
}
