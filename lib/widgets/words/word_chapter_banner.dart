// コード管理番号: VER-20260827-07
import 'package:flutter/material.dart';
import '../../models/word_section.dart';
import '../pixel_character_widget.dart';

/// チャプタードット絵キャラクター＆進捗バナー Widget
class WordChapterBanner extends StatelessWidget {
  final WordSection section;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color textSecondaryColor;
  final Color primaryColor;
  final int? totalChapterWords;
  final int? memorizedChapterWords;
  final bool isCharacterUnlocked;

  const WordChapterBanner({
    super.key,
    required this.section,
    this.cardColor = const Color(0xFFFFFDF9),
    this.borderColor = const Color(0xFFE0D8C8),
    this.textColor = const Color(0xFF2C3E50),
    this.textSecondaryColor = const Color(0xFF5D6D7E),
    this.primaryColor = const Color(0xFF2E8B57),
    this.totalChapterWords,
    this.memorizedChapterWords,
    this.isCharacterUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final chapterNum = int.tryParse(section.title.replaceAll(RegExp(r'[^0-9]'), '')) ??
        int.tryParse(section.key.replaceAll(RegExp(r'[^0-9]'), '')) ??
        1;
    // フィルターの影響を受けないグローバルなチャプター単語進捗を使用（未指定時はsection.wordsからフォールバック）
    final totalCount = totalChapterWords ?? section.words.length;
    final memorizedCount = memorizedChapterWords ??
        section.words.where((w) => w.retentionPoint >= 80).length;
    final percent = totalCount > 0 ? (memorizedCount / totalCount * 100).toInt() : 0;
    final isMastered = percent >= 80;

    final species = getCharacterSpecies(chapterNum);
    // キャラクター解放済みであれば、減衰で0%になっても名前と姿を維持 (未解放のみシルエット & ?????)
    final isUnlocked = isCharacterUnlocked || percent > 0;
    final charName = isUnlocked ? species.japaneseName : '? ? ? ? ?';

    final growthState = PixelCharacterWidget.stateFromRate(percent.toDouble(), isUnlocked);

    return SizedBox(
      height: 78.0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMastered ? primaryColor.withValues(alpha: 0.5) : borderColor,
            width: isMastered ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            // ドット絵キャラクター
            SizedBox(
              width: 48,
              height: 48,
              child: PixelCharacterWidget(
                speciesIndex: (chapterNum - 1).clamp(0, kTotalChapterCount - 1),
                growthState: growthState,
                actionState: isMastered ? CharacterActionState.humming : CharacterActionState.idle,
                size: 44,
              ),
            ),
            const SizedBox(width: 10),

            // キャラクター情報 & 80pt進捗 (2行でスッキリ表示)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ch.$chapterNum: $charName',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          if (isMastered)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MASTER ✨',
                                style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                              ),
                            )
                          else if (percent > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '育成中 🌱',
                                style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEAE0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '🔒 未学習',
                                style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '80pt定着: $memorizedCount/$totalCount 語',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: totalCount > 0 ? memorizedCount / totalCount : 0,
                            minHeight: 5,
                            backgroundColor: borderColor.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isMastered
                                  ? primaryColor
                                  : (percent >= 50 ? const Color(0xFFD97736) : Colors.amber.shade700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMastered ? primaryColor : (percent > 0 ? textColor : textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
