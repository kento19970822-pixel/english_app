// コード管理番号: VER-20260824-11
import 'package:flutter/material.dart';

/// 3種ソート（A-Z / Chap / Category）共通の粘着セクションヘッダー (F-06)
class StickySectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int totalCount;
  final int memorizedCount;
  final String sortMode; // 'az', 'chap', 'category'

  const StickySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.totalCount,
    required this.memorizedCount,
    required this.sortMode,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4EFE6);
    const borderColor = Color(0xFFE5DEC9);
    const primaryColor = Color(0xFF5F9E98);
    const secondaryColor = Color(0xFFECA882);
    const textPrimary = Color(0xFF2C302E);
    const textSecondary = Color(0xFF6B726E);

    final double rate = totalCount > 0 ? (memorizedCount / totalCount) : 0.0;
    final int percent = (rate * 100).toInt();

    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
          bottom: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // アイコン＆タイトル
          _buildIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 暗記進捗（Chap / Category の場合に進捗バー表示）
          if (sortMode != 'az') ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$memorizedCount/$totalCount 語',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: percent >= 80 ? primaryColor : secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: 80,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: rate,
                      backgroundColor: const Color(0xFFE5DEC9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percent >= 80 ? primaryColor : secondaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalCount 語',
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (sortMode) {
      case 'chap':
        return const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF5F9E98));
      case 'category':
        return const Icon(Icons.category_rounded, size: 18, color: Color(0xFFECA882));
      case 'az':
      default:
        return const Icon(Icons.sort_by_alpha_rounded, size: 18, color: Color(0xFF88A0A8));
    }
  }
}
