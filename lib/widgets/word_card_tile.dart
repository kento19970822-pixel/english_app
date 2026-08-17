// コード管理番号: VER-20260818-05
import 'package:flutter/material.dart';

import '../db/app_database.dart';

class WordCardTile extends StatefulWidget {
  final Word word;
  final bool showJapanese;
  final VoidCallback onSpeak;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onSwipeRight; // 右スワイプ: 暗記済み化
  final VoidCallback? onSwipeLeft; // 左スワイプ: 0ptリセット[cite: 4]

  const WordCardTile({
    super.key,
    required this.word,
    required this.showJapanese,
    required this.onSpeak,
    required this.onToggleFavorite,
    this.onSwipeRight,
    this.onSwipeLeft,
  });

  @override
  State<WordCardTile> createState() => _WordCardTileState();
}

class _WordCardTileState extends State<WordCardTile> {
  bool _isHolding = false;

  @override
  Widget build(BuildContext context) {
    final bool isJapaneseVisible = widget.showJapanese || _isHolding;

    return Dismissible(
      key: ValueKey('word_card_${widget.word.id}'),
      // 右スワイプ（緑）と左スワイプ（赤）の両方向を有効化
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右スワイプ処理（暗記済み化）
          widget.onSwipeRight?.call();
        } else if (direction == DismissDirection.endToStart) {
          // 左スワイプ処理（0ptリセット）
          widget.onSwipeLeft?.call();
        }
        // カードを消去せず元の位置に戻す
        return false;
      },
      // 👉 右スワイプ時の背景（緑背景 ＋ チェックアイコン）
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(4.0),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              '暗記済みにする',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      // 👈 左スワイプ時の背景（赤背景 ＋ リセットアイコン）
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(4.0),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '0ptにリセット',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.restore, color: Colors.white, size: 28),
          ],
        ),
      ),
      child: Card(
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
      ),
    );
  }
}
