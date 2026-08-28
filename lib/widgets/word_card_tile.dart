// コード管理番号: VER-20260824-12
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';

class WordCardTile extends StatefulWidget {
  final Word word;
  final bool showJapanese;
  final bool isKeyboardActive;
  final VoidCallback onSpeak;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onSwipeRight; // 右スワイプ: 暗記済み化 (80pt)
  final VoidCallback? onSwipeLeft; // 左スワイプ: 0ptリセット ＋ 制限フラグ
  final VoidCallback? onTap; // タップ（通常時詳細モーダル表示）
  final VoidCallback? onDoubleTap; // ダブルタップ（和訳OFF時詳細モーダル表示）

  const WordCardTile({
    super.key,
    required this.word,
    required this.showJapanese,
    this.isKeyboardActive = false,
    required this.onSpeak,
    required this.onToggleFavorite,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<WordCardTile> createState() => _WordCardTileState();
}

class _WordCardTileState extends State<WordCardTile> {
  bool? _overrideShowJapanese;

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
    final bool isMemorized = widget.word.isMemorized || widget.word.retentionPoint >= 80;
    final bool isRestricted = widget.word.isRestricted;
    final int pt = widget.word.retentionPoint;
    final Color indicatorColor = _getRetentionColor(pt, isMemorized);

    return Dismissible(
      key: ValueKey('word_card_${widget.word.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          widget.onSwipeRight?.call();
        } else if (direction == DismissDirection.endToStart) {
          HapticFeedback.lightImpact();
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
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMemorized
                ? const Color(0xFFC8E6C9)
                : (widget.word.isFavorite ? const Color(0xFFFFE082) : _borderColor),
            width: isMemorized || widget.word.isFavorite ? 1.2 : 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 左端スワイプ示唆（右スワイプで暗記化: エメラルド）
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B57).withAlpha(45),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                    ),
                  ),
                ),
              ),
              // 右端スワイプ示唆（左スワイプでリセット: オレンジ）
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFED8936).withAlpha(45),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
            splashColor: widget.isKeyboardActive ? Colors.transparent : null,
            highlightColor: widget.isKeyboardActive ? Colors.transparent : null,
            hoverColor: widget.isKeyboardActive ? Colors.transparent : null,
            onTap: widget.isKeyboardActive
                ? widget.onTap
                : (widget.showJapanese
                    ? widget.onTap
                    : () {
                        final currentlyVisible = _overrideShowJapanese ?? false;
                        final willShow = !currentlyVisible;
                        setState(() {
                          _overrideShowJapanese = willShow;
                        });
                        if (willShow) {
                          widget.onSpeak();
                        }
                      }),
            onDoubleTap: widget.isKeyboardActive
                ? widget.onDoubleTap
                : (widget.showJapanese ? null : (widget.onDoubleTap ?? widget.onTap)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8.0, 12, 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左端: 定着度インジケーター（縦バー・上下中央揃え）
                  Container(
                    width: 4.0,
                    height: 72,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(width: 10),

                // 単語・情報・和訳（洗練された3段構成）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1段目: バッジ群 ＆ 右側操作ボタン（音声 / Ch / お気に入り）
                      Row(
                        children: [
                          // 左側: バッジ群
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 品詞バッジ
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EEF5),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: const Color(0xFFBDD0E0), width: 0.6),
                                    ),
                                    child: Text(
                                      AppDatabase.toShortJapanesePos(widget.word.partOfSpeech, fallbackJp: widget.word.japanese),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A6B82),
                                      ),
                                    ),
                                  ),
                                  if (widget.word.totalSenses > 1) ...[
                                    const SizedBox(width: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE7F6),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: const Color(0xFFD1C4E9), width: 0.6),
                                      ),
                                      child: Text(
                                        '語義 ${widget.word.senseIndex}/${widget.word.totalSenses}',
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5E35B1),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (widget.word.baseForm != null && widget.word.baseForm!.isNotEmpty) ...[
                                    const SizedBox(width: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E1),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: const Color(0xFFFFE082), width: 0.6),
                                      ),
                                      child: Text(
                                        '原形: ${widget.word.baseForm}',
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8D6E63),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 3),
                                  // 定着度ポイント
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
                                    decoration: BoxDecoration(
                                      color: indicatorColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: indicatorColor, width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$pt pt',
                                          style: TextStyle(
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.bold,
                                            color: isMemorized ? const Color(0xFF2E7D32) : _textPrimary,
                                          ),
                                        ),
                                        if (widget.word.pointDecreasedTotal > 0) ...[
                                          const SizedBox(width: 1.5),
                                          Text(
                                            '(-${widget.word.pointDecreasedTotal})',
                                            style: const TextStyle(
                                              fontSize: 8.0,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD96B6B),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isMemorized) ...[
                                    const SizedBox(width: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        '✓ 覚えた',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (isRestricted) ...[
                                    const SizedBox(width: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        '⚠️ 70pt',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // 右側: 音声・Ch・お気に入り（押しやすいタップ領域）
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  color: _primaryAccent,
                                  size: 18,
                                ),
                                tooltip: '発音を聴く',
                                onPressed: widget.onSpeak,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEAE0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ch.${widget.word.chapter}',
                                  style: const TextStyle(
                                    fontSize: 9.0,
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
                                  size: 19,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  widget.onToggleFavorite();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 2段目: 英単語（カード全体の垂直中央に配置）
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          widget.word.english,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                            letterSpacing: 0.1,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 3段目: 日本語の意味（和訳またはタップで和訳）
                      isJapaneseVisible
                          ? Text(
                              widget.word.japanese,
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EFE6),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _borderColor, width: 0.6),
                                ),
                                child: const Text(
                                  'タップで和訳',
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w500,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),
),
);
  }
}
