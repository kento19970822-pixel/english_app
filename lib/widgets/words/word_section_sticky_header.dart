// コード管理番号: VER-20260827-06
import 'package:flutter/material.dart';
import '../../models/word_section.dart';

/// 単語一覧 Sticky ヘッダー Delegate
class WordSectionStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WordSection section;
  final String sortMode;
  final Color bgColor;
  final Color borderColor;
  final Color primaryColor;
  final Color textColor;
  final Color textSecondaryColor;

  WordSectionStickyHeaderDelegate({
    required this.section,
    required this.sortMode,
    this.bgColor = const Color(0xFFF9F6F0),
    this.borderColor = const Color(0xFFE0D8C8),
    this.primaryColor = const Color(0xFF2E8B57),
    this.textColor = const Color(0xFF2C3E50),
    this.textSecondaryColor = const Color(0xFF5D6D7E),
  });

  @override
  double get minExtent => 44.0;
  @override
  double get maxExtent => 44.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    String title = section.title;
    IconData icon = Icons.bookmark_rounded;

    if (sortMode == 'chap') {
      title = 'Chapter ${section.title}';
      icon = Icons.menu_book_rounded;
    } else if (sortMode == 'az') {
      title = section.title;
      icon = Icons.sort_by_alpha_rounded;
    } else if (sortMode == 'cat') {
      title = section.title;
      icon = Icons.category_rounded;
    }

    final totalCount = section.words.length;
    final memorizedCount = section.words.where((w) => w.isMemorized).length;
    final percent = totalCount > 0 ? (memorizedCount / totalCount * 100).toInt() : 0;

    return Container(
      height: 44.0,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$memorizedCount/$totalCount 語',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: percent >= 80 ? primaryColor : const Color(0xFFD97736),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 80,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? memorizedCount / totalCount : 0,
                    backgroundColor: borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent >= 80 ? primaryColor : const Color(0xFFD97736),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant WordSectionStickyHeaderDelegate oldDelegate) {
    return oldDelegate.section != section || oldDelegate.sortMode != sortMode;
  }
}
