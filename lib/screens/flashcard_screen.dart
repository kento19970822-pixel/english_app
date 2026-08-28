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
  late List<Word> _remainingWords;
  final List<PreviousCardResult> _historyStack = [];
  bool _isEnToJa = true; // true: 英➔和, false: 和➔英

  int _totalCount = 0;
  int _memorizedCount = 0;
  int _reviewCount = 0;
  bool _isSessionFinished = false;

  @override
  void initState() {
    super.initState();
    _remainingWords = List.from(widget.words);
    _totalCount = widget.words.length;

    // 画面表示直後に第1問目の英語音声を自動再生
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playCurrentWordTts();
    });
  }

  void _playCurrentWordTts() {
    if (_remainingWords.isNotEmpty) {
      TtsService.instance.speak(_remainingWords.first.english);
    }
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isEnToJa = !_isEnToJa;
    });
  }

  Future<void> _handleSwiped(bool isRight) async {
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
      // 右スワイプ: 暗記済 (80pt化 / memorized: true / restricted: false)
      _memorizedCount++;
      await widget.database.markAsMemorizedManual(currentWord.id);
    } else {
      // 左スワイプ: 要復習 (0pt化 / memorized: false / restricted: true)
      _reviewCount++;
      await widget.database.resetRetentionManual(currentWord.id);
    }

    if (_remainingWords.isEmpty) {
      setState(() {
        _isSessionFinished = true;
      });
      _showCompletionDialog();
    } else {
      setState(() {});
      // 次の単語の音声を自動再生
      _playCurrentWordTts();
    }
  }

  Future<void> _handleUndo() async {
    if (_historyStack.isEmpty) return;
    HapticFeedback.mediumImpact();

    final lastItem = _historyStack.removeLast();

    // DBの状態を以前の値に復元
    await widget.database.restoreWordState(
      id: lastItem.word.id,
      retentionPoint: lastItem.prevRetentionPoint,
      isMemorized: lastItem.prevIsMemorized,
      isRestricted: lastItem.prevIsRestricted,
      pointDecreasedTotal: lastItem.prevPointDecreasedTotal,
    );

    if (lastItem.isMemorizedAction) {
      _memorizedCount = mathMax(0, _memorizedCount - 1);
    } else {
      _reviewCount = mathMax(0, _reviewCount - 1);
    }

    setState(() {
      _isSessionFinished = false;
      _remainingWords.insert(0, lastItem.word);
    });

    _playCurrentWordTts();
  }

  int mathMax(int a, int b) => a > b ? a : b;

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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _remainingWords = List.from(widget.words);
                      _historyStack.clear();
                      _memorizedCount = 0;
                      _reviewCount = 0;
                      _isSessionFinished = false;
                    });
                    _playCurrentWordTts();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5F9E98),
                    side: const BorderSide(color: Color(0xFF5F9E98), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('もう一度解く', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _totalCount - _remainingWords.length;
    final progressText = '$currentIndex / $_totalCount 語';
    final lastResult = _historyStack.isNotEmpty ? _historyStack.last : null;

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.lightTextPrimary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTextPrimary,
              ),
            ),
            Text(
              progressText,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 英➔和 / 和➔英 切替ボタン
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: BouncyScaleTap(
              onTap: _toggleMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F9E98).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5F9E98).withAlpha(75)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF5F9E98)),
                    const SizedBox(width: 4),
                    Text(
                      _isEnToJa ? '英 ➔ 和' : '和 ➔ 英',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F9E98),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 直前カード答え合わせ HUD
            AnswersHud(
              lastResult: lastResult,
              onUndo: _handleUndo,
              canUndo: _historyStack.isNotEmpty,
            ),

            const Spacer(),

            // カードスタックエリア
            if (_remainingWords.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  // 背後のカード（次問）
                  if (_remainingWords.length > 1)
                    Transform.translate(
                      offset: const Offset(0, 14),
                      child: Transform.scale(
                        scale: 0.94,
                        child: Opacity(
                          opacity: 0.7,
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
                    ),

                  // 最前面のカード
                  SwipeableFlashcard(
                    key: ValueKey('front_${_remainingWords[0].id}'),
                    word: _remainingWords[0],
                    isEnToJa: _isEnToJa,
                    isFront: true,
                    onSwiped: _handleSwiped,
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

            // 下部ナビゲーションヒントバー
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 左スワイプボタン（タップでも操作可能）
                  BouncyScaleTap(
                    onTap: () => _handleSwiped(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFED8936).withAlpha(100)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFFED8936)),
                          SizedBox(width: 6),
                          Text('要復習', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFED8936))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // 右スワイプボタン（タップでも操作可能）
                  BouncyScaleTap(
                    onTap: () => _handleSwiped(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2E8B57).withAlpha(100)),
                      ),
                      child: const Row(
                        children: [
                          Text('暗記完了', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E8B57))),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2E8B57)),
                        ],
                      ),
                    ),
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
