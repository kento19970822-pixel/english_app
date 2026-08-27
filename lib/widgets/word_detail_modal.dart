// コード管理番号: VER-20260827-01
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/app_database.dart';
import '../models/word_detail_model.dart';
import '../services/tts_service.dart';

/// 単語詳細モーダル (F-22)
/// 発音記号・複数語義・品詞・例文・連語・定着度/減算pt・前後ナビ・上端下スワイプ終了
class WordDetailModal extends StatefulWidget {
  final List<Word> wordList;
  final int initialIndex;
  final AppDatabase database;
  final VoidCallback? onFavoriteChanged;

  const WordDetailModal({
    super.key,
    required this.wordList,
    required this.initialIndex,
    required this.database,
    this.onFavoriteChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Word> wordList,
    required int initialIndex,
    required AppDatabase database,
    VoidCallback? onFavoriteChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WordDetailModal(
        wordList: wordList,
        initialIndex: initialIndex,
        database: database,
        onFavoriteChanged: onFavoriteChanged,
      ),
    );
  }

  @override
  State<WordDetailModal> createState() => _WordDetailModalState();
}

class _WordDetailModalState extends State<WordDetailModal> {
  late int _currentIndex;
  late Word _currentWord;
  late WordDetail _detail;
  bool _isFavorite = false;
  final ScrollController _scrollController = ScrollController();
  double _dragOffsetY = 0.0;

  // テーマカラー
  static const Color _bgColor = Color(0xFFFBF7EE);
  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _secondaryAccent = Color(0xFFECA882);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _borderColor = Color(0xFFE5DEC9);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.wordList.length - 1);
    _loadWordAt(_currentIndex);
  }

  void _loadWordAt(int index) {
    setState(() {
      _currentIndex = index;
      _currentWord = widget.wordList[_currentIndex];
      _detail = WordDetail.fromWord(_currentWord);
      _isFavorite = _currentWord.isFavorite;
      _dragOffsetY = 0.0;
    });
    // 単語切り替え時に自動発音
    TtsService.instance.speak(_currentWord.english);
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.selectionClick();
    final nextFav = !_isFavorite;
    setState(() {
      _isFavorite = nextFav;
    });
    await widget.database.toggleFavorite(_currentWord.id, nextFav);
    widget.onFavoriteChanged?.call();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      _loadWordAt(_currentIndex - 1);
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.wordList.length - 1) {
      HapticFeedback.lightImpact();
      _loadWordAt(_currentIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Transform.translate(
      offset: Offset(0, _dragOffsetY),
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (_scrollController.hasClients && _scrollController.offset <= 0) {
            if (details.primaryDelta != null && details.primaryDelta! > 0) {
              setState(() {
                _dragOffsetY = (_dragOffsetY + details.primaryDelta!).clamp(0.0, 300.0);
              });
            }
          }
        },
        onVerticalDragEnd: (details) {
          if (_dragOffsetY > 80.0) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _dragOffsetY = 0.0;
            });
          }
        },
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // スワイプバーハンドル
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // ヘッダー部
              _buildHeader(),

              const Divider(height: 1, color: _borderColor),

              // コンテンツ部（スクロール）
              Flexible(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is OverscrollNotification && notification.overscroll < 0) {
                      setState(() {
                        _dragOffsetY = (_dragOffsetY - notification.overscroll * 0.5).clamp(0.0, 300.0);
                      });
                    }
                    if (notification is ScrollEndNotification) {
                      if (_dragOffsetY > 80.0) {
                        Navigator.of(context).pop();
                      } else if (_dragOffsetY > 0) {
                        setState(() {
                          _dragOffsetY = 0.0;
                        });
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 語義一覧 & 例文
                        _buildSensesSection(),

                        const SizedBox(height: 16),

                        // コロケーション・連語情報（存在する場合）
                        if (_detail.collocations.isNotEmpty) ...[
                          _buildCollocationsSection(),
                          const SizedBox(height: 16),
                        ],

                        // 学習進捗ステータス
                        _buildLearningStatusSection(),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: _borderColor),

              // ボトム操作ナビゲーションバー
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー（英単語・発音記号・TTS・お気に入り・バッジ）
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 単語スペル ＆ 発音記号
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _detail.english,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // TTS発音ボタン
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: _primaryAccent, size: 24),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        TtsService.instance.speak(_detail.english);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      splashRadius: 20,
                    ),
                  ],
                ),
                if (_detail.phonetic != null && _detail.phonetic!.isNotEmpty)
                  Text(
                    _detail.phonetic!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),

          // バッジ群（CEFR / Chap / お気に入り）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CEFR バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primaryAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _detail.cefr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _primaryAccent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // チャプターバッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _secondaryAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Ch.${_detail.chapter}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _secondaryAccent,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // お気に入りトグルボタン
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _isFavorite ? const Color(0xFFD4B86A) : _textSecondary.withValues(alpha: 0.5),
                  size: 28,
                ),
                onPressed: _toggleFavorite,
                splashRadius: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 語義一覧 & 例文
  Widget _buildSensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 16, color: _primaryAccent),
            const SizedBox(width: 6),
            const Text(
              '意味と例文',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${_detail.senses.length}つの語義',
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._detail.senses.asMap().entries.map((entry) {
          final idx = entry.key;
          final sense = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 語義番号・品詞・日本語訳
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _primaryAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '[${sense.partOfSpeech}]',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A6B82),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sense.meaningJa,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                // 例文（存在する場合）
                if (sense.exampleEn != null && sense.exampleEn!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                sense.exampleEn!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: _textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_outlined, size: 18, color: _primaryAccent),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                TtsService.instance.speak(sense.exampleEn!);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              splashRadius: 16,
                            ),
                          ],
                        ),
                        if (sense.exampleJa != null && sense.exampleJa!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            sense.exampleJa!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  /// コロケーション・連語セクション
  Widget _buildCollocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.link_rounded, size: 16, color: _secondaryAccent),
            SizedBox(width: 6),
            Text(
              'よく使われる組み合わせ（コロケーション）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _detail.collocations.map((colloc) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borderColor),
              ),
              child: Text(
                colloc,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 学習進捗ステータスセクション
  Widget _buildLearningStatusSection() {
    final isEmerald = _detail.retentionPoint >= 80;
    final isCoral = _detail.retentionPoint > 0 && _detail.retentionPoint < 80;
    final statusColor = isEmerald
        ? _primaryAccent
        : (isCoral ? _secondaryAccent : const Color(0xFFB0B7B3));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 16, color: statusColor),
              const SizedBox(width: 6),
              const Text(
                '記憶定着ステータス',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              // 定着度ポイント
              Text(
                '${_detail.retentionPoint} pt',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              // 減算累計ポイント（存在する場合）
              if (_detail.pointDecreasedTotal > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '(-${_detail.pointDecreasedTotal} pt)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD96B6B),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // 定着度プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_detail.retentionPoint / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),

          // 正解/誤答カウント
          Row(
            children: [
              Text(
                '正解: ${_detail.correctCount}回',
                style: const TextStyle(fontSize: 11, color: _textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                '不正解: ${_detail.wrongCount}回',
                style: const TextStyle(fontSize: 11, color: _textSecondary),
              ),
              const Spacer(),
              if (_detail.isMemorized)
                const Text(
                  '🟩 暗記達成済',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _primaryAccent),
                )
              else if (_detail.isRestricted)
                const Text(
                  '⚠️ 本日上限70pt',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _secondaryAccent),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// ボトム操作ナビゲーションバー（[← 前へ] [閉じる] [次へ →]）
  Widget _buildBottomNav() {
    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < widget.wordList.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _bgColor,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 前へボタン
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                label: const Text('前へ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                onPressed: canPrev ? _goToPrevious : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  disabledForegroundColor: _textSecondary.withValues(alpha: 0.4),
                  side: BorderSide(color: canPrev ? _borderColor : _borderColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 閉じるボタン
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('閉じる', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),

            // 次へボタン
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                label: const Text('次へ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onPressed: canNext ? _goToNext : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  disabledForegroundColor: _textSecondary.withValues(alpha: 0.4),
                  side: BorderSide(color: canNext ? _borderColor : _borderColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
