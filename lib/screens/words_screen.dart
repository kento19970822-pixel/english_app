// コード管理番号: VER-20260816-90
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';

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
  bool _isLoading = true;
  final FlutterTts _flutterTts = FlutterTts();

  // フィルター用ステート
  bool _onlyFavorites = false;
  String _selectedCefrFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadAndImportWords();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
  }

  // クォーテーション＆前後の空白を徹底的に除去
  String _cleanText(String text) {
    return text.replaceAll('"', '').replaceAll("'", '').trim();
  }

  // カンマ区切り分割（ダブルクォーテーションを考慮）
  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final RegExp regExp = RegExp(r'(?:^|,)(?:"([^"]*)"|([^,]*))');
    for (final Match match in regExp.allMatches(line)) {
      String value = match.group(1) ?? match.group(2) ?? '';
      result.add(_cleanText(value));
    }
    return result;
  }

  // DBクリア & CSV再読み込み
  Future<void> _loadAndImportWords({bool forceReset = false}) async {
    setState(() => _isLoading = true);

    try {
      var currentWords = await widget.database.getAllWords();

      // 強制リフレッシュ、またはデータ内の最初の単語にダブルクォーテーションが残っている場合にDB再構築
      bool needsRebuild =
          forceReset ||
          currentWords.isEmpty ||
          (currentWords.isNotEmpty && currentWords.first.english.contains('"'));

      if (needsRebuild) {
        // 1. DB内の全単語データを一度クリアする
        await widget.database.clearAllWords();

        // 2. CSV読み込み
        final rawData = await rootBundle.loadString('assets/words.csv');
        final lines = const LineSplitter().convert(rawData);

        if (lines.isNotEmpty) {
          // ヘッダー行の解析 ("word","CEFR","Japanese",...)
          final headerRow = _parseCsvLine(lines[0]);
          int wordIdx = -1;
          int cefrIdx = -1;
          int japaneseIdx = -1;

          for (int i = 0; i < headerRow.length; i++) {
            final col = headerRow[i].toLowerCase();
            if (col == 'word' || col == 'english') wordIdx = i;
            if (col == 'cefr') cefrIdx = i;
            if (col == 'japanese') japaneseIdx = i;
          }

          if (wordIdx == -1) wordIdx = 0;
          if (cefrIdx == -1) cefrIdx = 1;
          if (japaneseIdx == -1) japaneseIdx = 2;

          List<Map<String, String>> rawWords = [];
          for (int i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            final row = _parseCsvLine(line);
            if (row.length > wordIdx && row.length > japaneseIdx) {
              final eng = _cleanText(row[wordIdx]);
              final jpn = _cleanText(row[japaneseIdx]);
              final cefr = (cefrIdx < row.length)
                  ? _cleanText(row[cefrIdx])
                  : 'A1';

              if (eng.isNotEmpty && jpn.isNotEmpty) {
                rawWords.add({
                  'english': eng,
                  'japanese': jpn,
                  'cefr': cefr.isEmpty ? 'A1' : cefr.toUpperCase(),
                });
              }
            }
          }

          if (rawWords.isNotEmpty) {
            await widget.database.insertRawWords(rawWords);
            currentWords = await widget.database.getAllWords();
          }
        }
      }

      setState(() {
        _allWords = currentWords;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("CSV/DBインポートエラー: $e");
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredWords = _allWords.where((word) {
        // お気に入り
        if (_onlyFavorites && !word.isFavorite) {
          return false;
        }
        // CEFRレベル比較（クォーテーション除去・大文字揃え）
        if (_selectedCefrFilter != 'ALL') {
          final cleanCefr = _cleanText(word.cefr).toUpperCase();
          if (cleanCefr != _selectedCefrFilter) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _toggleFavorite(Word word) async {
    final nextFav = !word.isFavorite;
    await widget.database.toggleFavorite(word.id, nextFav);
    final updatedList = await widget.database.getAllWords();
    setState(() {
      _allWords = updatedList;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('単語一覧 (${_filteredWords.length}/${_allWords.length}件)'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'DB完全再構築',
            onPressed: () => _loadAndImportWords(forceReset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                FilterChip(
                  label: const Text('お気に入り'),
                  selected: _onlyFavorites,
                  selectedColor: Colors.amber[100],
                  checkmarkColor: Colors.amber[900],
                  onSelected: (bool selected) {
                    setState(() {
                      _onlyFavorites = selected;
                      _applyFilter();
                    });
                  },
                ),
                const SizedBox(width: 12),
                const Text('レベル: '),
                DropdownButton<String>(
                  value: _selectedCefrFilter,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('すべて')),
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                    DropdownMenuItem(value: 'B2', child: Text('B2')),
                    DropdownMenuItem(value: 'C1', child: Text('C1')),
                    DropdownMenuItem(value: 'C2', child: Text('C2')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedCefrFilter = value;
                        _applyFilter();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('データベースを再構築中...（3.7万件）'),
                      ],
                    ),
                  )
                : _filteredWords.isEmpty
                ? const Center(child: Text('条件に一致する単語がありません'))
                : ListView.builder(
                    itemCount: _filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = _filteredWords[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            word.english,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text('${word.japanese} (${word.cefr})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: Colors.indigo,
                                ),
                                onPressed: () => _speak(word.english),
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
                                onPressed: () => _toggleFavorite(word),
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
