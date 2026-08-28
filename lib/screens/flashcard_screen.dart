import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/app_database.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/bouncy_scale_tap.dart';
import '../widgets/flashcard/answers_hud.dart';
import '../widgets/flashcard/swipeable_flashcard.dart';

class FlashcardScreen extends StatefulWidget {
  final AppDatabase database;
  final List<Word> words;
  final String title;

  const FlashcardScreen({
    super.key,
    required this.database,
    required this.words,
    required this.title,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final FocusNode _focusNode = FocusNode();
  GlobalKey<SwipeableFlashcardState> _frontCardKey = GlobalKey<SwipeableFlashcardState>();
  final ValueNotifier<double> _dragProgressNotifier = ValueNotifier<double>(0.0);

  late List<Word> _remainingWords;
  final List<PreviousCardResult> _historyStack = [];
  final List<Word> _failedWords = []; // 要復習になった単語リスト（リトライ用）

  bool _isSelectingMode = true; // 0枚目（モード選択カード）表示中フラグ
  bool _isEnToJa = true; // true: 英➔和, false: 和➔英

  int _totalCount = 0;
  int _memorizedCount = 0;
  int _reviewCount = 0;
  int _streakCount = 0; // 連続暗記コンボ数
  bool _isSessionFinished = false;

  @override
  void initState() {
    super.initState();
    _remainingWords = List.from(widget.words);
    _totalCount = widget.words.length;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _dragProgressNotifier.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  void _playCurrentWordTts() {
    TtsService.instance.stop(); // 前の音声を即座に停止してキュー詰まり防止
    // 和➔英モードの時は日本語を見て英語を思い出すため、出題時の自動音声は再生しない（ネタバレ防止）
    if (!_isSelectingMode && _isEnToJa && _remainingWords.isNotEmpty) {
      TtsService.instance.speak(_remainingWords.first.english);
    }
  }

  void _handleSwiped(bool isRight) {
    _dragProgressNotifier.value = 0.0;

    if (_isSelectingMode) {
      // 0枚目: モード選択スワイプ (右: 英➔和, 左: 和➔英)
      HapticFeedback.mediumImpact();
      setState(() {
        _isEnToJa = isRight;
        _isSelectingMode = false;
        _frontCardKey = GlobalKey<SwipeableFlashcardState>();
      });
      _playCurrentWordTts();
      return;
    }

    if (_remainingWords.isEmpty) return;

    final currentWord = _remainingWords.removeAt(0);

    // 履歴に保存（Undo用）
    final historyItem = PreviousCardResult(
      word: currentWord,
      isMemorizedAction: isRight,
      prevRetentionPoint: currentWord.retentionPoint,
      prevIsMemorized: currentWord.isMemorized,
      prevIsRestricted: currentWord.isRestricted,
      prevPointDecreasedTotal: currentWord.pointDecreasedTotal,
    );
    _historyStack.add(historyItem);

    if (isRight) {
      // 右スワイプ: 暗記済 (80pt化)
      _memorizedCount++;
      _streakCount++;
      if (_streakCount == 5 || _streakCount == 10 || _streakCount == 20) {
        HapticFeedback.heavyImpact();
      }
      unawaited(widget.database.markAsMemorizedManual(currentWord.id));
    } else {
      // 左スワイプ: 要復習 (0pt化)
      _reviewCount++;
      _streakCount = 0; // コンボリセット
      if (!_failedWords.any((w) => w.id == currentWord.id)) {
        _failedWords.add(currentWord);
      }
      unawaited(widget.database.resetRetentionManual(currentWord.id));
    }

    if (_remainingWords.isEmpty) {
      setState(() {
        _isSessionFinished = true;
      });
      _showCompletionDialog();
    } else {
      setState(() {
        _frontCardKey = GlobalKey<SwipeableFlashcardState>();
      });
      _playCurrentWordTts();
    }
  }

  Future<void> _handleUndo() async {
    if (_isSelectingMode || _historyStack.isEmpty) return;
    HapticFeedback.mediumImpact();

    final lastItem = _historyStack.removeLast();

    // DBの状態を復元
    await widget.database.restoreWordState(
      id: lastItem.word.id,
      retentionPoint: lastItem.prevRetentionPoint,
      isMemorized: lastItem.prevIsMemorized,
      isRestricted: lastItem.prevIsRestricted,
      pointDecreasedTotal: lastItem.prevPointDecreasedTotal,
    );

    if (lastItem.isMemorizedAction) {
      _memorizedCount = mathMax(0, _memorizedCount - 1);
      _streakCount = mathMax(0, _streakCount - 1);
    } else {
      _reviewCount = mathMax(0, _reviewCount - 1);
      _failedWords.removeWhere((w) => w.id == lastItem.word.id);
    }

    _dragProgressNotifier.value = 0.0;
    setState(() {
      _isSessionFinished = false;
      _remainingWords.insert(0, lastItem.word);
      _frontCardKey = GlobalKey<SwipeableFlashcardState>();
    });

    _playCurrentWordTts();
  }

  int mathMax(int a, int b) => a > b ? a : b;

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _frontCardKey.currentState?.swipeRight();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _frontCardKey.currentState?.swipeLeft();
    } else if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _frontCardKey.currentState?.toggleFlip();
    } else if (event.logicalKey == LogicalKeyboardKey.keyZ &&
        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
      _handleUndo();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
    }
  }

  void _showCompletionDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE5DEC9)),
        ),
        title: const Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text(
              'スワイプ学習完了！',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C302E),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '全 $_totalCount 語のチェックが完了しました。',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B726E)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('暗記達成', style: TextStyle(fontSize: 12, color: Color(0xFF2E8B57), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$_memorizedCount 語', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E8B57))),
                    ],
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFFE5DEC9)),
                  Column(
                    children: [
                      const Text('要復習', style: TextStyle(fontSize: 12, color: Color(0xFFED8936), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$_reviewCount 語', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFED8936))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 要復習単語がある場合、即座にリトライできるボタン
              if (_failedWords.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _remainingWords = List.from(_failedWords);
                      _totalCount = _failedWords.length;
                      _failedWords.clear();
                      _historyStack.clear();
                      _memorizedCount = 0;
                      _reviewCount = 0;
                      _streakCount = 0;
                      _isSelectingMode = false;
                      _isSessionFinished = false;
                      _frontCardKey = GlobalKey<SwipeableFlashcardState>();
                    });
                    _playCurrentWordTts();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text('要復習の ${_failedWords.length} 語だけ再特訓'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED8936),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _remainingWords = List.from(widget.words);
                          _totalCount = widget.words.length;
                          _failedWords.clear();
                          _historyStack.clear();
                          _memorizedCount = 0;
                          _reviewCount = 0;
                          _streakCount = 0;
                          _isSelectingMode = true;
                          _isSessionFinished = false;
                          _frontCardKey = GlobalKey<SwipeableFlashcardState>();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5F9E98),
                        side: const BorderSide(color: Color(0xFF5F9E98), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('全問解き直す', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F9E98),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('単語帳に戻る', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _totalCount - _remainingWords.length;
    final progressText = _isSelectingMode ? 'モード選択' : '$currentIndex / $_totalCount 語';
    final progressFraction = _totalCount > 0 ? (currentIndex / _totalCount).clamp(0.0, 1.0) : 0.0;
    final lastResult = _historyStack.isNotEmpty ? _historyStack.last : null;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        backgroundColor: AppTheme.lightBg,
        appBar: AppBar(
          backgroundColor: AppTheme.lightBg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Column(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ① 目線誘導: 極細グラデーション進捗バー (高さ2.5px)
              Container(
                height: 2.5,
                width: double.infinity,
                color: const Color(0xFFE5DEC9),
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  widthFactor: _isSelectingMode ? 0.0 : progressFraction,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5F9E98), Color(0xFF2E8B57)],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ② 目線誘導: 直前カード答え合わせ HUD ＆ コンボバッジ
              if (!_isSelectingMode)
                AnswersHud(
                  lastResult: lastResult,
                  streakCount: _streakCount,
                )
              else
                const SizedBox(height: 48),

              const Spacer(),

              // ③ 【視線集中エリア】カードスタックエリア (局所リビルドでフリーズ完全防止)
              if (_isSelectingMode)
                SwipeableFlashcard(
                  key: _frontCardKey,
                  isModeSelector: true,
                  isEnToJa: true,
                  isFront: true,
                  onSwiped: _handleSwiped,
                  onSpeak: () {},
                )
              else if (_remainingWords.isNotEmpty)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背後のカード（局所リビルドでドラッグ追従）
                    if (_remainingWords.length > 1)
                      ValueListenableBuilder<double>(
                        valueListenable: _dragProgressNotifier,
                        builder: (context, progress, child) {
                          final backScale = 0.94 + (0.06 * progress);
                          final backOpacity = (0.65 + (0.35 * progress)).clamp(0.0, 1.0);
                          final backOffsetY = 10.0 * (1.0 - progress);

                          return Transform.translate(
                            offset: Offset(0, backOffsetY),
                            child: Transform.scale(
                              scale: backScale,
                              child: Opacity(
                                opacity: backOpacity,
                                child: SwipeableFlashcard(
                                  key: ValueKey('back_${_remainingWords[1].id}'),
                                  word: _remainingWords[1],
                                  isEnToJa: _isEnToJa,
                                  isFront: false,
                                  onSwiped: (_) {},
                                  onSpeak: () {},
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // 最前面のカード
                    SwipeableFlashcard(
                      key: _frontCardKey,
                      word: _remainingWords[0],
                      isEnToJa: _isEnToJa,
                      isFront: true,
                      onSwiped: _handleSwiped,
                      onDragProgress: (progress) {
                        _dragProgressNotifier.value = progress;
                      },
                      onSpeak: () => TtsService.instance.speak(_remainingWords[0].english),
                    ),
                  ],
                )
              else if (_isSessionFinished)
                const SizedBox.shrink()
              else
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF5F9E98)),
                ),

              const Spacer(),

              // ④ 【親指操作エリア】下部集中コントロールバー (片手操作に最適化)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. 左下: 終了（✕）ボタン
                    BouncyScaleTap(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
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
                        child: const Icon(Icons.close_rounded, size: 20, color: AppTheme.lightTextPrimary),
                      ),
                    ),

                    // 2. 中央アクションボタン群
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 左スワイプボタン
                        BouncyScaleTap(
                          onTap: () {
                            if (_frontCardKey.currentState != null) {
                              _frontCardKey.currentState!.swipeLeft();
                            } else {
                              _handleSwiped(false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFED8936).withAlpha(100)),
                            ),
                            child: Row(
                              children: [
                                if (!_isSelectingMode) ...[
                                  const Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFFED8936)),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _isSelectingMode ? '和 ➔ 英' : '要復習',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFED8936)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 右スワイプボタン
                        BouncyScaleTap(
                          onTap: () {
                            if (_frontCardKey.currentState != null) {
                              _frontCardKey.currentState!.swipeRight();
                            } else {
                              _handleSwiped(true);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF2E8B57).withAlpha(100)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _isSelectingMode ? '英 ➔ 和' : '暗記完了',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E8B57)),
                                ),
                                if (!_isSelectingMode) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF2E8B57)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 3. 右下: 戻す (Undo) ボタン
                    BouncyScaleTap(
                      onTap: (_historyStack.isNotEmpty && !_isSelectingMode) ? _handleUndo : () {},
                      child: Opacity(
                        opacity: (_historyStack.isNotEmpty && !_isSelectingMode) ? 1.0 : 0.35,
                        child: Container(
                          width: 44,
                          height: 44,
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
                          child: const Icon(Icons.undo_rounded, size: 20, color: AppTheme.lightTextPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
