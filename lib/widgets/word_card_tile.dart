// コード管理番号: VER-20260824-12
import 'package:flutter/material.dart';

import '../db/app_database.dart';

class WordCardTile extends StatefulWidget {
  final Word word;
  final bool showJapanese;
  final VoidCallback onSpeak;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onSwipeRight; // 右スワイプ: 暗記済み化 (80pt)
  final VoidCallback? onSwipeLeft; // 左スワイプ: 0ptリセット ＋ 制限フラグ

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

  // 定数パステルカラー
  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _secondaryAccent = Color(0xFFECA882);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _borderColor = Color(0xFFE5DEC9);

  @override
  Widget build(BuildContext context) {
    final bool isJapaneseVisible = widget.showJapanese || _isHolding;
    final bool isMemorized = widget.word.isMemorized;
    final bool isRestricted = widget.word.isRestricted;

    return Dismissible(
      key: ValueKey('word_card_${widget.word.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onSwipeRight?.call();
        } else if (direction == DismissDirection.endToStart) {
          widget.onSwipeLeft?.call();
        }
        return false;
      },
      // 👉 右スワイプ: 暗記済み（80pt）化
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              '暗記済みにする (80pt)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      // 👈 左スワイプ: 0ptリセット ＋ 制限フラグ付与
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373),
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '0ptにリセット (本日制限)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.restart_alt_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMemorized
                ? _primaryAccent.withAlpha(80)
                : _borderColor,
            width: isMemorized ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) {
            setState(() => _isHolding = true);
            widget.onSpeak();
          },
          onLongPressEnd: (_) => setState(() => _isHolding = false),
          onLongPressCancel: () => setState(() => _isHolding = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 暗記済みインジケータ
                Container(
                  width: 8,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isMemorized
                        ? _primaryAccent
                        : (widget.word.retentionPoint > 0
                            ? _secondaryAccent
                            : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                // 単語・発音・和訳エリア
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            widget.word.english,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.word.phonetic != null &&
                              widget.word.phonetic!.isNotEmpty)
                            Text(
                              widget.word.phonetic!,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          if (isRestricted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: const Text(
                                '⚠️ 本日上限70pt',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isJapaneseVisible
                            ? widget.word.japanese
                            : '•••••• (長押しで表示)',
                        style: TextStyle(
                          fontSize: 14,
                          color: isJapaneseVisible ? _textPrimary : _textSecondary.withAlpha(150),
                          fontStyle: isJapaneseVisible
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // 発音ボタン・レベルバッジ・お気に入りボタン
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: _primaryAccent,
                        size: 22,
                      ),
                      tooltip: '発音を聴く',
                      onPressed: widget.onSpeak,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEAE0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ch.${widget.word.chapter}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.word.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: widget.word.isFavorite
                            ? Colors.amber.shade700
                            : const Color(0xFFC0B8A5),
                        size: 24,
                      ),
                      onPressed: widget.onToggleFavorite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
