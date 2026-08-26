// コード管理番号: VER-20260824-12
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import '../services/sound_service.dart';

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
    final bool isMemorized = widget.word.isMemorized || widget.word.retentionPoint >= 80;
    final bool isRestricted = widget.word.isRestricted;
    final int pt = widget.word.retentionPoint;
    final Color indicatorColor = _getRetentionColor(pt, isMemorized);

    return Dismissible(
      key: ValueKey('word_card_${widget.word.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          SoundService.instance.playMemorized();
          widget.onSwipeRight?.call();
        } else if (direction == DismissDirection.endToStart) {
          SoundService.instance.playReset();
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
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isMemorized ? const Color(0xFFF8FDF9) : _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMemorized
                ? const Color(0xFF81C784)
                : _borderColor,
            width: isMemorized ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isMemorized ? const Color(0x124CAF50) : const Color(0x08000000),
              blurRadius: isMemorized ? 5 : 4,
              offset: const Offset(0, 1.5),
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
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 定着度ポイント4段階カラーインジケータ（タップ中インタラクション拡大対応）
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    width: _isPressed ? 7 : 5,
                    height: _isPressed ? 56 : 48,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(3),
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
                      // 1行目: 英単語 ＋ 定着度ポイント ＆ 上部操作ボタン（音声/Ch/お気に入り）
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
                                onPressed: () {
                                  if (!widget.word.isFavorite) {
                                    SoundService.instance.playFavorite();
                                  } else {
                                    HapticFeedback.lightImpact();
                                  }
                                  widget.onToggleFavorite();
                                },
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 2行目: 発音記号 ＆ カテゴリ ＆ 暗記バッジ（覚えた） ＆ 制限フラグ（常に2行目に固定配置）
                      if ((widget.word.phonetic != null && widget.word.phonetic!.isNotEmpty) ||
                          widget.word.category.isNotEmpty ||
                          isMemorized ||
                          isRestricted) ...[
                        const SizedBox(height: 2),
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
                            if (isMemorized) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '✓ 覚えた',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
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

                      // 3行目: 日本語訳（タップ切り替え ＆ アフォーダンス表示）
                      const SizedBox(height: 3),
                      if (isJapaneseVisible)
                        Text(
                          widget.word.japanese,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                            height: 1.25,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4EFE6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _borderColor,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded, size: 13, color: _textSecondary),
                              SizedBox(width: 4),
                              Text(
                                'タップで和訳を表示',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 4行目: 例文 ＆ 例文訳（存在する場合、はみ出しなく自然に全行表示）
                      if (widget.word.example != null &&
                          widget.word.example!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.word.example!,
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF555B58),
                                height: 1.3,
                              ),
                            ),
                            if (isJapaneseVisible &&
                                widget.word.exampleJp != null &&
                                widget.word.exampleJp!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.word.exampleJp!,
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: Color(0xFF7A827E),
                                  height: 1.3,
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
