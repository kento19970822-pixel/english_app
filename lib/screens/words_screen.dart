// コード管理番号: VER-20260818-06
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../db/app_database.dart';
import '../widgets/sticky_chapter_header.dart';
import '../widgets/word_card_tile.dart';

class WordsScreen extends StatefulWidget {
  final AppDatabase database;

  const WordsScreen({super.key, required this.database});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  List<Word> _allWords = [];
  List<Word> _filteredWords = [];

  int _selectedLevel = 0;
  int _selectedChapter = 0;
  bool _onlyFavorite = false;
  bool _showJapanese = true; // F-07: 和訳表示スイッチ（デフォルトON）
  String _searchQuery = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadWords();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    final words = await widget.database.getAllWords();
    setState(() {
      _allWords = words;
      _isLoading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      _filteredWords = _allWords.where((word) {
        if (_onlyFavorite && !word.isFavorite) {
          return false;
        }
        if (_selectedLevel != 0 && word.level != _selectedLevel) {
          return false;
        }
        if (_selectedChapter != 0 && word.chapter != _selectedChapter) {
          return false;
        }
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesEnglish = word.english.toLowerCase().contains(query);
          final matchesJapanese = word.japanese.contains(query);
          return matchesEnglish || matchesJapanese;
        }
        return true;
      }).toList();
    });
  }

  List<int> _getAvailableChapters() {
    final targetWords = _allWords.where((w) {
      if (_onlyFavorite && !w.isFavorite) {
        return false;
      }
      if (_selectedLevel != 0 && w.level != _selectedLevel) {
        return false;
      }
      return true;
    }).toList();

    final chapters = targetWords.map((w) => w.chapter).toSet().toList();
    chapters.sort();
    return chapters;
  }

  /// フィルタリングされた単語を章（chapter）ごとにグループ化するヘルパー
  Map<int, List<Word>> _groupWordsByChapter() {
    final Map<int, List<Word>> grouped = {};
    for (final word in _filteredWords) {
      grouped.putIfAbsent(word.chapter, () => []).add(word);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<void> _toggleFavoriteFast(Word targetWord) async {
    final newStatus = !targetWord.isFavorite;

    setState(() {
      final index = _allWords.indexWhere((w) => w.id == targetWord.id);
      if (index != -1) {
        _allWords[index] = _allWords[index].copyWith(isFavorite: newStatus);
      }
    });

    _applyFilter();
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

  Future<void> _rebuildDatabase() async {
    setState(() => _isLoading = true);
    try {
      final csvString = await rootBundle.loadString('assets/words.csv');
      final lines = csvString.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) return;

      final rawHeader = _parseCsvLine(lines.first);
      final header = rawHeader
          .map((h) => h.replaceAll('"', '').trim())
          .toList();

      final List<Map<String, String>> rawData = [];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line)
            .map((v) => v.replaceAll('"', '').trim())
            .toList();
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
      await _loadWords();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DBの再構築が完了しました（全${_allWords.length}件）')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableChapters = _getAvailableChapters();
    final groupedWords = _groupWordsByChapter();

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語帳'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'DB完全再構築',
            onPressed: _isLoading ? null : _rebuildDatabase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: '英語または日本語で検索',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _applyFilter();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedLevel,
                              decoration: const InputDecoration(
                                labelText: 'レベル',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text('すべてのレベル'),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('Level 1 (A1)'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Level 2 (A2)'),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text('Level 3 (B1)'),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text('Level 4 (B2)'),
                                ),
                                DropdownMenuItem(
                                  value: 5,
                                  child: Text('Level 5 (C1)'),
                                ),
                                DropdownMenuItem(
                                  value: 6,
                                  child: Text('Level 6 (C2)'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedLevel = val;
                                    _selectedChapter = 0;
                                  });
                                  _applyFilter();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue:
                                  availableChapters.contains(_selectedChapter)
                                  ? _selectedChapter
                                  : 0,
                              decoration: const InputDecoration(
                                labelText: '章 (Chapter)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 0,
                                  child: Text('すべての章'),
                                ),
                                ...availableChapters.map(
                                  (ch) => DropdownMenuItem(
                                    value: ch,
                                    child: Text('Ch. $ch'),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedChapter = val);
                                  _applyFilter();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FilterChip(
                            avatar: Icon(
                              _onlyFavorite ? Icons.star : Icons.star_border,
                              color: _onlyFavorite ? Colors.amber : Colors.grey,
                              size: 18,
                            ),
                            label: const Text('お気に入りのみ表示'),
                            selected: _onlyFavorite,
                            onSelected: (bool selected) {
                              setState(() {
                                _onlyFavorite = selected;
                                _selectedChapter = 0;
                              });
                              _applyFilter();
                            },
                          ),
                          // F-07: 和訳ON/OFF表示切り替えスイッチ
                          Row(
                            children: [
                              const Text(
                                '和訳表示',
                                style: TextStyle(fontSize: 13),
                              ),
                              Switch(
                                value: _showJapanese,
                                activeColor: Colors.indigo,
                                onChanged: (val) {
                                  setState(() {
                                    _showJapanese = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '表示中: ${_filteredWords.length} 件',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredWords.isEmpty
                      ? const Center(child: Text('該当する単語が見つかりません'))
                      : CustomScrollView(
                          slivers: groupedWords.entries.map((entry) {
                            final chapter = entry.key;
                            final wordsInChapter = entry.value;

                            return SliverMainAxisGroup(
                              slivers: [
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _StickyHeaderDelegate(
                                    child: StickyChapterHeader(
                                      chapter: chapter,
                                      wordCount: wordsInChapter.length,
                                    ),
                                  ),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final word = wordsInChapter[index];
                                    return WordCardTile(
                                      word: word,
                                      showJapanese: _showJapanese,
                                      onSpeak: () => _speak(word.english),
                                      onToggleFavorite: () =>
                                          _toggleFavoriteFast(word),
                                      // F-08: 👉 右スワイプ（暗記済み化 / 定着度100pt）
                                      onSwipeRight: () async {
                                        await widget.database
                                            .updateRetentionPoint(word.id, 100);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '「${word.english}」を暗記済みに設定しました',
                                              ),
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      // F-08: 👈 左スワイプ（0ptリセット）
                                      onSwipeLeft: () async {
                                        await widget.database
                                            .updateRetentionPoint(word.id, 0);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '「${word.english}」の定着度を0ptにリセットしました',
                                              ),
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  }, childCount: wordsInChapter.length),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
    );
  }
}

/// Flutter標準の CustomScrollView 用の粘着ヘッダーデリゲート
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 40.0;

  @override
  double get minExtent => 40.0;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
