import 'package:flutter/material.dart';
import '../../db/app_database.dart';
import '../../theme/app_theme.dart';

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

  const AnswersHud({
    super.key,
    required this.lastResult,
  });

  @override
  Widget build(BuildContext context) {
    if (lastResult == null) {
      return const SizedBox(height: 48); // 直前結果がない時は空の高さプレースホルダー
    }

    final res = lastResult!;
    final isMemorized = res.isMemorizedAction;
    final badgeColor = isMemorized ? const Color(0xFF2E8B57) : const Color(0xFFED8936);
    final badgeBg = isMemorized ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final badgeText = isMemorized ? '暗記済 ✓' : '要復習 🔄';

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
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
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    res.word.english,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  ':',
                  style: TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    res.word.japanese,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
