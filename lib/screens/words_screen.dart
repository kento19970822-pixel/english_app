// コード管理番号: VER-20260817-28
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';

class WordsScreen extends StatefulWidget {
  final AppDatabase database;

  const WordsScreen({super.key, required this.database});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  List<Word> _allWords = [];
  List<Word> _filteredWords = [];

  int _selectedLevel = 0; // 0: 全て, 1: Level 1(A1) ... 6: Level 6(C2)
  int _selectedChapter = 0; // 0: 全て
  String _searchQuery = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  /// DBからの単語全件取得と初期化
  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    final words = await widget.database.getAllWords();
    setState(() {
      _allWords = words;
      _isLoading = false;
    });
    _applyFilter();
  }

  /// フィルター条件の適用
  void _applyFilter() {
    setState(() {
      _filteredWords = _allWords.where((word) {
        if (_selectedLevel != 0 && word.level != _selectedLevel) return false;
        if (_selectedChapter != 0 && word.chapter != _selectedChapter)
          return false;

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

  /// 選択されているレベル（または全体）に存在する実際のチャプター番号一覧を取得
  List<int> _getAvailableChapters() {
    final targetWords = _selectedLevel == 0
        ? _allWords
        : _allWords.where((w) => w.level == _selectedLevel).toList();

    final chapters = targetWords.map((w) => w.chapter).toSet().toList();
    chapters.sort();
    return chapters;
  }

  /// Dart標準機能のみを用いた安全なCSV1行パース関数
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

  /// DB完全再構築処理（CSV取り込み）
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
  Widget build(BuildContext context) {
    final availableChapters = _getAvailableChapters();

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
                              value: _selectedLevel,
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
                              value:
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
                      : ListView.builder(
                          itemCount: _filteredWords.length,
                          itemBuilder: (context, index) {
                            final word = _filteredWords[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Text(
                                      word.english,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if (word.phonetic != null &&
                                        word.phonetic!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        word.phonetic!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(word.japanese),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(
                                        'L${word.level}-Ch${word.chapter}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        word.isFavorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: word.isFavorite
                                            ? Colors.amber
                                            : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        await widget.database.toggleFavorite(
                                          word.id,
                                          !word.isFavorite,
                                        );
                                        _loadWords();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
