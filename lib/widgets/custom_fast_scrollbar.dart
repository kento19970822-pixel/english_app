// コード管理番号: VER-20260826-SCROLLBAR-HAPTIC
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// 単語帳などの長大リスト専用の超軽量・高パフォーマンスなカスタムスクロールバー
///
/// 特徴:
/// 1. iPhone純正メールアプリのようなホールド時（mediumImpact）＆離した時（lightImpact）＆移動時（selectionClick）のハプティクス振動フィードバック
/// 2. フレーム合体（Frame-Coalescing）とVsync同期ジャンプにより、Web版でも処理落ちゼロ・120Hz/60Hzの滑らかな操作性を実現
/// 3. 画面上下10%に余白を設け、中央80%の範囲内でスムーズに移動
/// 4. 通常時は幅6px、タップ・ドラッグ中は幅16pxに拡大＆シャドウ強調
class CustomFastScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  final Color thumbColor;
  final double topMarginRatio;
  final double bottomMarginRatio;
  final double? topOffset;
  final double? bottomOffset;

  const CustomFastScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.thumbColor = const Color(0xFF5F9E98),
    this.topMarginRatio = 0.10,
    this.bottomMarginRatio = 0.10,
    this.topOffset,
    this.bottomOffset,
  });

  @override
  State<CustomFastScrollbar> createState() => _CustomFastScrollbarState();
}

class _CustomFastScrollbarState extends State<CustomFastScrollbar> {
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier<bool>(false);

  double? _pendingJumpOffset;
  bool _isFrameScheduled = false;
  int _lastHapticMilestone = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerScroll);
  }

  @override
  void didUpdateWidget(covariant CustomFastScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerScroll);
      widget.controller.addListener(_onControllerScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerScroll);
    _progressNotifier.dispose();
    _isDraggingNotifier.dispose();
    super.dispose();
  }

  void _onControllerScroll() {
    if (!widget.controller.hasClients || _isDraggingNotifier.value) return;
    final pos = widget.controller.position;
    if (pos.maxScrollExtent <= 0) {
      _progressNotifier.value = 0.0;
      return;
    }
    final p = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    _progressNotifier.value = p;
  }

  void _handleDragStart(double localY, double totalHeight) {
    _isDraggingNotifier.value = true;
    // iPhone純正メールアプリのような「カクッ」としたホールド触覚フィードバック
    HapticFeedback.mediumImpact();
    _handleDragUpdate(localY, totalHeight);
  }

  void _handleDragUpdate(double localY, double totalHeight) {
    if (!widget.controller.hasClients) return;
    final topMargin = widget.topOffset ?? (totalHeight * widget.topMarginRatio);
    final bottomMargin = widget.bottomOffset ?? (totalHeight * widget.bottomMarginRatio);
    final usableHeight = totalHeight - topMargin - bottomMargin;
    if (usableHeight <= 0) return;

    final double progress = ((localY - topMargin) / usableHeight).clamp(0.0, 1.0);
    _progressNotifier.value = progress;

    // スクロール区間通過ごとの心地よい刻み振動（selectionClick）
    final int currentMilestone = (progress * 30).floor();
    if (currentMilestone != _lastHapticMilestone) {
      _lastHapticMilestone = currentMilestone;
      HapticFeedback.selectionClick();
    }

    final maxExtent = widget.controller.position.maxScrollExtent;
    if (maxExtent > 0) {
      _requestThrottledJump(progress * maxExtent);
    }
  }

  void _handleDragEnd() {
    _isDraggingNotifier.value = false;
    if (_pendingJumpOffset != null && widget.controller.hasClients) {
      final maxExtent = widget.controller.position.maxScrollExtent;
      widget.controller.jumpTo(_pendingJumpOffset!.clamp(0.0, maxExtent));
    }
    _pendingJumpOffset = null;
    _lastHapticMilestone = -1;
    // 指を離した際の「ククッ」としたリリース触覚フィードバック
    HapticFeedback.lightImpact();
  }

  /// Vsyncフレーム合体ジャンプ（毎フレーム最大1回のレイアウト実行で処理落ちを完全防止）
  void _requestThrottledJump(double targetOffset) {
    _pendingJumpOffset = targetOffset;
    if (!_isFrameScheduled) {
      _isFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        _isFrameScheduled = false;
        if (_pendingJumpOffset != null && widget.controller.hasClients) {
          final maxExtent = widget.controller.position.maxScrollExtent;
          widget.controller.jumpTo(_pendingJumpOffset!.clamp(0.0, maxExtent));
          _pendingJumpOffset = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final topMargin = widget.topOffset ?? (totalHeight * widget.topMarginRatio);
        final bottomMargin = widget.bottomOffset ?? (totalHeight * widget.bottomMarginRatio);
        final trackHeight = (totalHeight - topMargin - bottomMargin).clamp(100.0, double.infinity);
        const double thumbHeight = 44.0;

        return Stack(
          children: [
            // リスト本体
            widget.child,

            // 右端のスクロールバー操作エリア（幅36pxで確実にタッチ可能な判定領域）
            Positioned(
              top: topMargin,
              bottom: bottomMargin,
              right: 0,
              width: 36,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (details) {
                  _handleDragStart(details.localPosition.dy + topMargin, totalHeight);
                },
                onVerticalDragUpdate: (details) {
                  _handleDragUpdate(details.localPosition.dy + topMargin, totalHeight);
                },
                onVerticalDragEnd: (_) => _handleDragEnd(),
                onVerticalDragCancel: () => _handleDragEnd(),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isDraggingNotifier,
                  builder: (context, isDragging, _) {
                    return ValueListenableBuilder<double>(
                      valueListenable: _progressNotifier,
                      builder: (context, progress, _) {
                        final availableTravel = trackHeight - thumbHeight;
                        final thumbTop = (availableTravel * progress).clamp(0.0, availableTravel);

                        return Stack(
                          children: [
                            // つまみ（サム）
                            Positioned(
                              top: thumbTop,
                              right: 2,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutCubic,
                                width: isDragging ? 16.0 : 6.0,
                                height: isDragging ? 54.0 : thumbHeight,
                                decoration: BoxDecoration(
                                  color: isDragging
                                      ? widget.thumbColor
                                      : widget.thumbColor.withAlpha(160),
                                  borderRadius: BorderRadius.circular(isDragging ? 8.0 : 3.0),
                                  boxShadow: isDragging
                                      ? [
                                          BoxShadow(
                                            color: widget.thumbColor.withAlpha(120),
                                            blurRadius: 10,
                                            offset: const Offset(-2, 0),
                                            spreadRadius: 1.5,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isDragging
                                    ? const Center(
                                        child: Icon(
                                          Icons.unfold_more_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
