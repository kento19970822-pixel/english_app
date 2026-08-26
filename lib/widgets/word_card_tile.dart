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
  bool? _overrideShowJapanese;
  bool _isPressed = false;

  // 定数パステルカラー
  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _secondaryAccent = Color(0xFFECA882);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _borderColor = Color(0xFFE5DEC9);

  @override
  void didUpdateWidget(covariant WordCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showJapanese != widget.showJapanese) {
      _overrideShowJapanese = null;
    }
  }

  Color _getRetentionColor(int pt, bool isMem) {
    if (isMem || pt >= 80) return const Color(0xFF4CAF50); // 🟢 80〜100pt: 暗記達成
    if (pt >= 50) return const Color(0xFFE6A23C); // 🟡 50〜79pt: 定着中（高）
    if (pt > 0) return _secondaryAccent; // 🟠 1〜49pt: 学習初期
    return const Color(0xFFDCD4BE); // ⚪ 0pt: 未学習
  }

  @override
  Widget build(BuildContext context) {
    final bool isJapaneseVisible = _overrideShowJapanese ?? widget.showJapanese;
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
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '定着度リセット (0pt/制限)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.refresh_rounded, color: Colors.white, size: 26),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHighlightChanged: (val) {
            setState(() => _isPressed = val);
          },
          onTap: widget.showJapanese
              ? null
              : () {
                  final currentlyVisible = _overrideShowJapanese ?? false;
                  final willShow = !currentlyVisible;
                  setState(() {
                    _overrideShowJapanese = willShow;
                  });
                  if (willShow) {
                    widget.onSpeak();
                  }
                },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 定着度ポイント4段階カラーインジケータ（タップ中インタラクション拡大対応）
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    width: _isPressed ? 8 : 5,
                    height: _isPressed ? 60 : 52,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: _isPressed
                          ? [
                              BoxShadow(
                                color: indicatorColor.withAlpha(120),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 単語・発音・和訳・例文エリア
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1行目: 英単語 ＋ 定着度ポイント ＋ 暗記バッジ ＆ 上部操作ボタン（音声/Ch/お気に入り）
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.word.english,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: _textPrimary,
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // 定着度ポイントバッジ
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: indicatorColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: indicatorColor, width: 1),
                                  ),
                                  child: Text(
                                    '$pt pt',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isMemorized ? const Color(0xFF2E7D32) : _textPrimary,
                                    ),
                                  ),
                                ),
                                if (isMemorized) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '✓ 覚えた',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 上部操作ボタン群（カード上部・英単語の高さに配置）
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  color: _primaryAccent,
                                  size: 20,
                                ),
                                tooltip: '発音を聴く',
                                onPressed: widget.onSpeak,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEAE0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Ch.${widget.word.chapter}',
                                  style: const TextStyle(
                                    fontSize: 10,
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
                                  size: 22,
                                ),
                                onPressed: widget.onToggleFavorite,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 2行目: 発音記号 ＆ カテゴリ ＆ 制限フラグ（常に2行目に固定配置）
                      if ((widget.word.phonetic != null && widget.word.phonetic!.isNotEmpty) ||
                          widget.word.category.isNotEmpty ||
                          isRestricted) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (widget.word.phonetic != null && widget.word.phonetic!.isNotEmpty) ...[
                              Text(
                                widget.word.phonetic!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (widget.word.category.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEAE0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.word.category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (isRestricted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(4),
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
                      ],

                      // 3行目: 日本語訳（タップ切り替え）
                      const SizedBox(height: 4),
                      Text(
                        isJapaneseVisible
                            ? widget.word.japanese
                            : '•••••• (タップで表示)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isJapaneseVisible ? _textPrimary : _textSecondary.withAlpha(150),
                          fontStyle: isJapaneseVisible
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),

                      // 4行目: 例文 ＆ 例文訳（存在する場合、はみ出しなく自然に全行表示）
                      if (widget.word.example != null &&
                          widget.word.example!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.word.example!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF555B58),
                                height: 1.35,
                              ),
                            ),
                            if (isJapaneseVisible &&
                                widget.word.exampleJp != null &&
                                widget.word.exampleJp!.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                widget.word.exampleJp!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF7A827E),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
