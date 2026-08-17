// コード管理番号: VER-20260818-02
import 'package:flutter/material.dart';

import '../db/app_database.dart';

class WordCardTile extends StatefulWidget {
  final Word word;
  final bool showJapanese;
  final VoidCallback onSpeak;
  final VoidCallback onToggleFavorite;

  const WordCardTile({
    super.key,
    required this.word,
    required this.showJapanese,
    required this.onSpeak,
    required this.onToggleFavorite,
  });

  @override
  State<WordCardTile> createState() => _WordCardTileState();
}

class _WordCardTileState extends State<WordCardTile> {
  bool _isHolding = false;

  @override
  Widget build(BuildContext context) {
    final bool isJapaneseVisible = widget.showJapanese || _isHolding;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) {
          setState(() {
            _isHolding = true;
          });
          widget.onSpeak();
        },
        onLongPressEnd: (_) {
          setState(() {
            _isHolding = false;
          });
        },
        onLongPressCancel: () {
          setState(() {
            _isHolding = false;
          });
        },
        child: ListTile(
          title: Row(
            children: [
              Text(
                widget.word.english,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (widget.word.phonetic != null &&
                  widget.word.phonetic!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  widget.word.phonetic!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ],
          ),
          subtitle: Text(
            isJapaneseVisible ? widget.word.japanese : '•••••• (長押しで表示)',
            style: TextStyle(
              color: isJapaneseVisible ? Colors.black87 : Colors.grey[500],
              fontStyle: isJapaneseVisible
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                tooltip: '発音を聴く',
                onPressed: widget.onSpeak,
              ),
              Chip(
                label: Text(
                  'L${widget.word.level}-Ch${widget.word.chapter}',
                  style: const TextStyle(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(
                  widget.word.isFavorite ? Icons.star : Icons.star_border,
                  color: widget.word.isFavorite ? Colors.amber : Colors.grey,
                ),
                onPressed: widget.onToggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
