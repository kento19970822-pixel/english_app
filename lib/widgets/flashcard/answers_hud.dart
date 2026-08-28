import 'package:flutter/material.dart';
import '../../db/app_database.dart';
import '../../theme/app_theme.dart';
import '../common/bouncy_scale_tap.dart';

class PreviousCardResult {
  final Word word;
  final bool isMemorizedAction; // true: 右スワイプ(暗記), false: 左スワイプ(復習)
  final int prevRetentionPoint;
  final bool prevIsMemorized;
  final bool prevIsRestricted;
  final int prevPointDecreasedTotal;

  PreviousCardResult({
    required this.word,
    required this.isMemorizedAction,
    required this.prevRetentionPoint,
    required this.prevIsMemorized,
    required this.prevIsRestricted,
    required this.prevPointDecreasedTotal,
  });
}

class AnswersHud extends StatelessWidget {
  final PreviousCardResult? lastResult;
  final VoidCallback onUndo;
  final bool canUndo;

  const AnswersHud({
    super.key,
    required this.lastResult,
    required this.onUndo,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context) {
    if (lastResult == null) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        child: const Text(
          '👈 左: 要復習   |   👉 右: 暗記完了',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
          ),
        ),
      );
    }

    final res = lastResult!;
    final isMemorized = res.isMemorizedAction;
    final badgeColor = isMemorized ? const Color(0xFF2E8B57) : const Color(0xFFED8936);
    final badgeBg = isMemorized ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final badgeText = isMemorized ? '暗記済 ✓' : '要復習 🔄';

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withAlpha(80)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  res.word.english,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  res.word.japanese,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canUndo)
            BouncyScaleTap(
              onTap: onUndo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDED7C5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.undo_rounded, size: 14, color: AppTheme.lightTextPrimary),
                    SizedBox(width: 4),
                    Text(
                      '戻す',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
