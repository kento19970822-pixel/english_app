import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../db/app_database.dart';
import '../../theme/app_theme.dart';
import '../common/bouncy_scale_tap.dart';

class SwipeableFlashcard extends StatefulWidget {
  final Word? word;
  final bool isModeSelector; // 0枚目のモード選択カードかどうか
  final bool isEnToJa; // true: 英語が表, false: 日本語が表
  final Function(bool isRight) onSwiped;
  final VoidCallback onSpeak;
  final bool isFront; // スタックの最前面かどうか

  const SwipeableFlashcard({
    super.key,
    this.word,
    this.isModeSelector = false,
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
      duration: const Duration(milliseconds: 240),
    );
    _flipAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
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
    if (widget.isModeSelector) return; // モード選択カードはフリップ不要
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
    final threshold = screenWidth * 0.25;

    if (_dragOffset.dx > threshold) {
      // 右スワイプ確定
      _flyOut(Offset(screenWidth * 1.5, _dragOffset.dy), true);
    } else if (_dragOffset.dx < -threshold) {
      // 左スワイプ確定
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
    final rotationAngle = (_dragOffset.dx / screenWidth) * 0.22;

    // スワイプスタンプの透明度
    final swipeProgress = (_dragOffset.dx.abs() / (screenWidth * 0.25)).clamp(0.0, 1.0);
    final isSwipingRight = _dragOffset.dx > 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 250,
        ),
        child: AspectRatio(
          aspectRatio: 1.48, // スマホでも常に黄金比の横長長方形
          child: Transform.translate(
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
                        ..setEntry(3, 2, 0.001)
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
    if (widget.isModeSelector) {
      return _buildModeSelectorCard(isSwipingRight: isSwipingRight, swipeProgress: swipeProgress);
    }

    final word = widget.word!;
    final isShowingEnglish = widget.isEnToJa ? !isBack : isBack;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isBack ? const Color(0xFFDED7C5) : AppTheme.lightBorder,
          width: isBack ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景ウォーターマーク
          Positioned(
            right: -10,
            bottom: -15,
            child: Opacity(
              opacity: 0.035,
              child: Icon(
                isShowingEnglish ? Icons.translate_rounded : Icons.menu_book_rounded,
                size: 130,
                color: AppTheme.lightTextPrimary,
              ),
            ),
          ),

          // カードメイン内容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 上部バー（品詞タグ & CEFR & 反転インジケータ）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F9E98).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        word.partOfSpeech.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F9E98),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5DEC9),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            word.cefr,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isBack ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
                          size: 15,
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTextPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 発音音声ボタン
                  BouncyScaleTap(
                    onTap: widget.onSpeak,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F9E98).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded, size: 15, color: Color(0xFF5F9E98)),
                          SizedBox(width: 4),
                          Text(
                            '音声',
                            style: TextStyle(
                              fontSize: 11,
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTextPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    word.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const Spacer(),

                // 下部ヒント
                Text(
                  isBack ? 'タップで戻す' : 'タップで答えを確認',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTextSecondary.withAlpha(180),
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
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSwipingRight ? const Color(0xFF2E8B57) : const Color(0xFFED8936),
                      width: 3.0,
                    ),
                  ),
                  alignment: isSwipingRight ? Alignment.topLeft : Alignment.topRight,
                  padding: const EdgeInsets.all(20.0),
                  child: Transform.rotate(
                    angle: isSwipingRight ? -0.15 : 0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSwipingRight ? const Color(0xFF2E8B57) : const Color(0xFFED8936),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSwipingRight ? 'MEMORIZED ✓' : 'REVIEW 🔄',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
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

  Widget _buildModeSelectorCard({
    required bool isSwipingRight,
    required double swipeProgress,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5F9E98), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F9E98).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '出題モードを選択',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F9E98),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'スワイプしてスタート！',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFED8936).withAlpha(100)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 14, color: Color(0xFFED8936)),
                          SizedBox(width: 4),
                          Text('和 ➔ 英', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFED8936))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2E8B57).withAlpha(100)),
                      ),
                      child: const Row(
                        children: [
                          Text('英 ➔ 和', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E8B57))),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2E8B57)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // モード選択スタンプ
          if (swipeProgress > 0.05)
            Positioned.fill(
              child: Opacity(
                opacity: (swipeProgress * 1.5).clamp(0.0, 0.92),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSwipingRight
                        ? const Color(0xFF2E8B57).withAlpha(38)
                        : const Color(0xFFED8936).withAlpha(38),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSwipingRight ? const Color(0xFF2E8B57) : const Color(0xFFED8936),
                      width: 3.0,
                    ),
                  ),
                  alignment: isSwipingRight ? Alignment.centerRight : Alignment.centerLeft,
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSwipingRight ? const Color(0xFF2E8B57) : const Color(0xFFED8936),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSwipingRight ? '英 ➔ 和 で開始 👉' : '👈 和 ➔ 英 で開始',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
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
