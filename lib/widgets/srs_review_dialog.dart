// コード管理番号: VER-20260827-14
import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../services/srs_service.dart';
import '../theme/app_theme.dart';
import 'active_recall_card.dart';

/// SRS ＆ Active Recall 復習ダイアログ/画面
class SrsReviewDialog extends StatefulWidget {
  final AppDatabase database;
  final VoidCallback? onComplete;

  const SrsReviewDialog({
    super.key,
    required this.database,
    this.onComplete,
  });

  static Future<void> show(BuildContext context, AppDatabase database, {VoidCallback? onComplete}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SrsReviewDialog(database: database, onComplete: onComplete),
    );
  }

  @override
  State<SrsReviewDialog> createState() => _SrsReviewDialogState();
}

class _SrsReviewDialogState extends State<SrsReviewDialog> {
  List<Word> _dueWords = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  int _rememberedCount = 0;
  int _forgottenCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDueWords();
  }

  Future<void> _loadDueWords() async {
    final words = await SrsService.instance.getReviewSessionWords(widget.database, limit: 15);
    if (mounted) {
      setState(() {
        _dueWords = words;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRate(int qualityScore) async {
    if (_currentIndex >= _dueWords.length) return;
    final currentWord = _dueWords[_currentIndex];

    await SrsService.instance.recordReviewResult(
      database: widget.database,
      wordId: currentWord.id,
      qualityScore: qualityScore,
    );

    if (qualityScore >= 2) {
      _rememberedCount++;
    } else {
      _forgottenCount++;
    }

    if (_currentIndex + 1 < _dueWords.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _currentIndex++;
      });
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final primaryAccent = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final progress = _dueWords.isEmpty ? 1.0 : (_currentIndex / _dueWords.length).clamp(0.0, 1.0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ヘッダーバー ＆ 閉じるボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFED8936).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFED8936), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SRS 能動的想起（Active Recall）',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Text(
                      'エビングハウス忘却曲線に基づく最適復習',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 進捗バー
          LinearProgressIndicator(
            value: progress,
            backgroundColor: primaryAccent.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
            minHeight: 4,
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryAccent))
                : _dueWords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF48BB78), size: 48),
                            const SizedBox(height: 12),
                            Text('本日の復習はすべて完了しています！', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                            const SizedBox(height: 4),
                            Text('明日また新しい単語が期日を迎えます。', style: TextStyle(fontSize: 12, color: textSecondary)),
                          ],
                        ),
                      )
                    : _currentIndex < _dueWords.length
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('問題  / ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary)),
                                    Text('定着度: pt', style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: ActiveRecallCard(
                                    key: ValueKey(_dueWords[_currentIndex].id),
                                    word: _dueWords[_currentIndex],
                                    onRate: _handleRate,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : // セッション完了画面
                        Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.celebration_rounded, color: Color(0xFFECC94B), size: 56),
                                  const SizedBox(height: 16),
                                  Text('復習セッション完了！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: primaryAccent.withAlpha(50)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('覚えている: $_rememberedCount語', style: const TextStyle(color: Color(0xFF48BB78), fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 16),
                                        Text('要復習: $_forgottenCount語', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('閉じる', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
