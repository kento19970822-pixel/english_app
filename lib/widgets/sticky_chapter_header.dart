// コード管理番号: VER-20260818-01
import 'package:flutter/material.dart';

class StickyChapterHeader extends StatelessWidget {
  final int chapter;
  final int wordCount;

  const StickyChapterHeader({
    super.key,
    required this.chapter,
    required this.wordCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.0,
      color: Colors.indigo.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '📖 Chapter $chapter',
            style: TextStyle(
              color: Colors.indigo.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          Text(
            '$wordCount 語',
            style: TextStyle(color: Colors.indigo.shade700, fontSize: 13.0),
          ),
        ],
      ),
    );
  }
}
