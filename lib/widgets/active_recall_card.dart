// コード管理番号: VER-20260827-13
import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// Active Recall（能動的想起）学習カード
/// 日本語 ＆ 頭文字ヒントから頭の中で英単語を想起させ、タップで解答を展開する認知科学準拠カード
class ActiveRecallCard extends StatefulWidget {
  final Word word;
  final Function(int qualityScore)? onRate;
  final VoidCallback? onNext;

  const ActiveRecallCard({
    super.key,
    required this.word,
    this.onRate,
    this.onNext,
  });

  @override
  State<ActiveRecallCard> createState() => _ActiveRecallCardState();
}

class _ActiveRecallCardState extends State<ActiveRecallCard> {
  bool _isRevealed = false;

  /// 英単語を穴埋めヒント形式に変換（例: 'apple' -> 'a _ _ _ e'）
  String _generateRecallHint(String english) {
    final clean = english.trim();
    if (clean.length <= 2) return clean;
    final first = clean[0];
    final last = clean[clean.length - 1];
    final blanks = List.filled(clean.length - 2, '_').join(' ');
    return '$first $blanks $last (${clean.length}文字)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final primaryAccent = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final posColors = AppTheme.getPosBadgeColors(widget.word.partOfSpeech, isDark: isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isRevealed ? primaryAccent.withAlpha(120) : borderCol, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ヘッダー: 品詞バッジ ＆ CEFR ＆ チャプター
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: posColors.bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.word.partOfSpeech.isEmpty ? '品詞' : widget.word.partOfSpeech,
                  style: TextStyle(
                    color: posColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.word.cefr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Ch.',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 日本語の意味（常に表示）
          Text(
            widget.word.japanese,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // 3. 能動的想起（Active Recall）エリア
          if (!_isRevealed) ...[
            // 未開示: 穴埋めヒント ＆ タップして想起
            InkWell(
              onTap: () {
                setState(() => _isRevealed = true);
                TtsService.instance.speak(widget.word.english);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  color: primaryAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryAccent.withAlpha(60), strokeAlign: BorderSide.strokeAlignInside),
                ),
                child: Column(
                  children: [
                    Text(
                      _generateRecallHint(widget.word.english),
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 16, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'タップして答えを確認',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // 開示後: 正解の英単語 ＆ 発音記号 ＆ 音声再生ボタン
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: primaryAccent.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.word.english,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.volume_up_rounded, color: primaryAccent, size: 22),
                        onPressed: () => TtsService.instance.speak(widget.word.english),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                  if (widget.word.phonetic != null && widget.word.phonetic!.isNotEmpty)
                    Text(
                      widget.word.phonetic!,
                      style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                    ),
                  if (widget.word.example != null && widget.word.example!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.word.example!,
                      style: TextStyle(fontSize: 12, color: textPrimary, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. SRS自己評価ボタン（間隔反復スケジューリング）
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onRate?.call(1); // 忘れた (1日後)
                      widget.onNext?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('忘れた', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('1日後', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onRate?.call(3); // 覚えている (3〜7日後)
                      widget.onNext?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('覚えている', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('数日後', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
