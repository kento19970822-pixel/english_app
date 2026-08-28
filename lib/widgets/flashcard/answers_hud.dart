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
  final int streakCount;

  const AnswersHud({
    super.key,
    required this.lastResult,
    this.streakCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (lastResult == null && streakCount < 3) {
      return const SizedBox(height: 48); // 直前結果がない時は空の高さプレースホルダー
    }

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
          if (lastResult != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: lastResult!.isMemorizedAction ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (lastResult!.isMemorizedAction ? const Color(0xFF2E8B57) : const Color(0xFFED8936)).withAlpha(80),
                ),
              ),
              child: Text(
                lastResult!.isMemorizedAction ? '暗記済 ✓' : '要復習 🔄',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: lastResult!.isMemorizedAction ? const Color(0xFF2E8B57) : const Color(0xFFED8936),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      lastResult!.word.english,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    ':',
                    style: TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastResult!.word.japanese,
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
          ] else ...[
            const Spacer(),
          ],

          // 3連続以上のコンボバッジ
          if (streakCount >= 3) ...[
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: streakCount >= 10
                      ? [const Color(0xFFFF8C00), const Color(0xFFFF4500)]
                      : streakCount >= 5
                          ? [const Color(0xFF5F9E98), const Color(0xFF2E8B57)]
                          : [const Color(0xFFD4B86A), const Color(0xFFD97736)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    streakCount >= 10 ? '🎉' : '🔥',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$streakCount連続',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
