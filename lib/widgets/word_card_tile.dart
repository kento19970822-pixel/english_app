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

  Color _getRetentionColor(int pt, bool isMem) {
    if (isMem || pt >= 80) return const Color(0xFF4CAF50); // 🟢 80〜100pt: 暗記達成
    if (pt >= 50) return const Color(0xFFE6A23C); // 🟡 50〜79pt: 定着中（高）
    if (pt > 0) return _secondaryAccent; // 🟠 1〜49pt: 学習初期
    return const Color(0xFFDCD4BE); // ⚪ 0pt: 未学習
  }

  @override
  Widget build(BuildContext context) {
    final bool isJapaneseVisible = widget.showJapanese || _isHolding;
    final bool isMemorized = widget.word.isMemorized;
    final bool isRestricted = widget.word.isRestricted;
    final int pt = widget.word.retentionPoint;
    final Color indicatorColor = _getRetentionColor(pt, isMemorized);

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
                // 定着度ポイント4段階カラーインジケータ (緑:80pt+, 黄:50-79pt, 橙:1-49pt, 灰:0pt)
                Container(
                  width: 6,
                  height: 44,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(3),
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
                          // 定着度ポイントバッジ（数値＆カラー表示）
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: indicatorColor.withAlpha(35),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: indicatorColor.withAlpha(120), width: 1),
                            ),
                            child: Text(
                              '$pt pt',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: indicatorColor == const Color(0xFFDCD4BE)
                                    ? _textSecondary
                                    : (indicatorColor == const Color(0xFFE6A23C)
                                        ? Colors.amber.shade900
                                        : indicatorColor),
                              ),
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
                      if (widget.word.example != null &&
                          widget.word.example!.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          widget.word.example!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF6B726E),
                            height: 1.2,
                          ),
                        ),
                        if (isJapaneseVisible &&
                            widget.word.exampleJp != null &&
                            widget.word.exampleJp!.trim().isNotEmpty)
                          Text(
                            widget.word.exampleJp!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888F8C),
                              height: 1.2,
                            ),
                          ),
                      ],
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
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
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
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
