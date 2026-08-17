// コード管理番号: VER-20260817-20
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

  /// フィルター条件（レベル・章・検索キーワード）の適用
  void _applyFilter() {
    setState(() {
      _filteredWords = _allWords.where((word) {
        // レベルフィルター
        if (_selectedLevel != 0 && word.level != _selectedLevel) {
          return false;
        }
        // チャプターフィルター
        if (_selectedChapter != 0 && word.chapter != _selectedChapter) {
          return false;
        }
        // 検索キーワードフィルター
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

  /// 選択されているレベルに存在する最大チャプター数を取得
  int _getMaxChapterForSelectedLevel() {
    final targetWords = _selectedLevel == 0
        ? _allWords
        : _allWords.where((w) => w.level == _selectedLevel).toList();

    if (targetWords.isEmpty) return 0;
    return targetWords.map((w) => w.chapter).reduce((a, b) => a > b ? a : b);
  }

  /// DB完全再構築処理
  Future<void> _rebuildDatabase() async {
    setState(() => _isLoading = true);
    try {
      final csvString = await rootBundle.loadString('assets/words.csv');
      final lines = csvString.split('\n');
      if (lines.isEmpty) return;

      final header = lines.first.trim().split(',');
      final List<Map<String, String>> rawData = [];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = line
            .split(',')
            .map((e) => e.replaceAll('"', '').trim())
            .toList();
        if (values.length >= header.length) {
          final map = <String, String>{};
          for (var j = 0; j < header.length; j++) {
            map[header[j].replaceAll('"', '').trim()] = values[j];
          }
          rawData.add(map);
        }
      }

      await widget.database.clearAllWords();
      await widget.database.insertRawWords(rawData);
      await _loadWords();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('DBの完全再構築が完了しました！')));
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
    final maxChapters = _getMaxChapterForSelectedLevel();

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
                // 検索 ＆ 絞り込みフィルターエリア
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // 検索バー
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
                      // レベル & チャプター選択ドロップダウン
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
                                    _selectedChapter = 0; // レベル変更時は章選択をリセット
                                  });
                                  _applyFilter();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedChapter,
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
                                ...List.generate(
                                  maxChapters,
                                  (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Text('Ch. ${index + 1}'),
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
                // 該当件数表示（修正箇所）
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
                // 単語一覧リスト
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
                                    // 発音記号が存在する場合のみ表示
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
