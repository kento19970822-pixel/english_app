// コード管理番号: VER-20260816-19
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../db/app_database.dart';

class WordsScreen extends StatefulWidget {
  final AppDatabase database;

  const WordsScreen({super.key, required this.database});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final FlutterTts flutterTts = FlutterTts();
  List<Word> allWords = [];
  bool isLoading = true;
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadWords();
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.45);
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  Future<void> _loadWords() async {
    final words = await widget.database.getAllWords();
    setState(() {
      allWords = words;
      isLoading = false;
    });
  }

  Future<void> _toggleFavorite(Word word) async {
    final nextFav = !word.isFavorite;
    await widget.database.toggleFavorite(word.id, nextFav);
    _loadWords(); // リストを再読み込み
  }

  Future<void> _playAudio(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedWords = showFavoritesOnly
        ? allWords.where((w) => w.isFavorite).toList()
        : allWords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語帳'),
        actions: [
          IconButton(
            icon: Icon(
              showFavoritesOnly ? Icons.star : Icons.star_border,
              color: showFavoritesOnly ? Colors.amber : null,
            ),
            tooltip: showFavoritesOnly ? 'すべて表示' : 'お気に入りのみ',
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedWords.isEmpty
          ? Center(
              child: Text(
                showFavoritesOnly ? 'お気に入りに登録された単語はありません ★' : '単語が登録されていません',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: displayedWords.length,
              itemBuilder: (context, index) {
                final word = displayedWords[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      word.english,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      word.japanese,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Lv.${word.level}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up,
                            color: Colors.indigo,
                          ),
                          onPressed: () => _playAudio(word.english),
                        ),
                        IconButton(
                          icon: Icon(
                            word.isFavorite ? Icons.star : Icons.star_border,
                            color: word.isFavorite ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(word),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
