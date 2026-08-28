import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../db/app_database.dart';
import '../../theme/app_theme.dart';
import '../common/bouncy_scale_tap.dart';

class SwipeableFlashcard extends StatefulWidget {
  final Word word;
  final bool isEnToJa; // true: 英語が表, false: 日本語が表
  final Function(bool isRight) onSwiped;
  final VoidCallback onSpeak;
  final bool isFront; // スタックの最前面かどうか

  const SwipeableFlashcard({
    super.key,
    required this.word,
    required this.isEnToJa,
    required this.onSwiped,
    required this.onSpeak,
    this.isFront = true,
  });

  @override
  State<SwipeableFlashcard> createState() => _SwipeableFlashcardState();
}

class _SwipeableFlashcardState extends State<SwipeableFlashcard>
    with TickerProviderStateMixin {
  // スワイプ用
  Offset _dragOffset = Offset.zero;
  late AnimationController _swipeAnimController;
  late Animation<Offset> _swipeAnimation;

  // 3Dフリップ用
  bool _showBack = false;
  late AnimationController _flipAnimController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _flipAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipAnimController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _swipeAnimController.dispose();
    _flipAnimController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.selectionClick();
    if (_showBack) {
      _flipAnimController.reverse();
    } else {
      _flipAnimController.forward();
    }
    setState(() {
      _showBack = !_showBack;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isFront) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isFront) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.28;

    if (_dragOffset.dx > threshold) {
      // 右スワイプ確定 (暗記)
      _flyOut(Offset(screenWidth * 1.5, _dragOffset.dy), true);
    } else if (_dragOffset.dx < -threshold) {
      // 左スワイプ確定 (復習)
      _flyOut(Offset(-screenWidth * 1.5, _dragOffset.dy), false);
    } else {
      // 元の位置へ戻る
      _swipeAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOutBack),
      )..addListener(() {
          setState(() {
            _dragOffset = _swipeAnimation.value;
          });
        });
      _swipeAnimController.forward(from: 0.0);
    }
  }

  void _flyOut(Offset target, bool isRight) {
    HapticFeedback.mediumImpact();
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeInCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _swipeAnimation.value;
        });
      });
    _swipeAnimController.forward(from: 0.0).then((_) {
      widget.onSwiped(isRight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rotationAngle = (_dragOffset.dx / screenWidth) * 0.25; // 傾き

    // スワイプスタンプの透明度
    final swipeProgress = (_dragOffset.dx.abs() / (screenWidth * 0.28)).clamp(0.0, 1.0);
    final isSwipingRight = _dragOffset.dx > 0;

    return Transform.translate(
      offset: _dragOffset,
      child: Transform.rotate(
        angle: rotationAngle,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTap: _toggleFlip,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final isUnder = angle > math.pi / 2;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 3Dパースペクティブ
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isUnder
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _buildCardContent(isBack: true, isSwipingRight: isSwipingRight, swipeProgress: swipeProgress),
                      )
                    : _buildCardContent(isBack: false, isSwipingRight: isSwipingRight, swipeProgress: swipeProgress),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required bool isBack,
    required bool isSwipingRight,
    required double swipeProgress,
  }) {
    final word = widget.word;

    // 表裏の判定
    // 英➔和モード: 表=英語, 裏=日本語
    // 和➔英モード: 表=日本語, 裏=英語
    final isShowingEnglish = widget.isEnToJa ? !isBack : isBack;

    return Container(
      width: double.infinity,
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.lightCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isBack ? const Color(0xFFDED7C5) : AppTheme.lightBorder,
          width: isBack ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景ウォーターマーク
          Positioned(
            right: -15,
            bottom: -20,
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                isShowingEnglish ? Icons.translate_rounded : Icons.menu_book_rounded,
                size: 180,
                color: AppTheme.lightTextPrimary,
              ),
            ),
          ),

          // カードメイン内容
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 上部バー（品詞タグ & CEFR & 反転インジケータ）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F9E98).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        word.partOfSpeech.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F9E98),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5DEC9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            word.cefr,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isBack ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
                          size: 16,
                          color: const Color(0xFFB0A998),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // メインテキスト表示
                if (isShowingEnglish) ...[
                  // 英語表示
                  Text(
                    word.english,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 発音音声ボタン
                  BouncyScaleTap(
                    onTap: widget.onSpeak,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F9E98).withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF5F9E98)),
                          SizedBox(width: 6),
                          Text(
                            '音声を聞く',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5F9E98),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // 日本語表示
                  Text(
                    word.japanese,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTextPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    word.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const Spacer(),

                // 下部ヒント
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: AppTheme.lightTextSecondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'タップで答えを確認 / 戻す',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // スワイプスタンプ演出 (MEMORIZED / REVIEW)
          if (swipeProgress > 0.05)
            Positioned.fill(
              child: Opacity(
                opacity: (swipeProgress * 1.5).clamp(0.0, 0.92),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSwipingRight
                        ? const Color(0xFF2E8B57).withAlpha(38)
                        : const Color(0xFFED8936).withAlpha(38),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isSwipingRight ? const Color(0xFF2E8B57) : const Color(0xFFED8936),
                      width: 3.5,
                    ),
                  ),
                  alignment: isSwipingRight ? Alignment.topLeft : Alignment.topRight,
                  padding: const EdgeInsets.all(28.0),
                  child: Transform.rotate(
                    angle: isSwipingRight ? -0.2 : 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSwipingRight ? const Color(0xFF2E8B57) : const Color(0xFFED8936),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isSwipingRight ? 'MEMORIZED ✓' : 'REVIEW 🔄',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
