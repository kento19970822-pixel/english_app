// コード管理番号: VER-20260826-SCROLLBAR
import 'package:flutter/material.dart';

/// 単語帳などの長大リスト専用の超軽量・高パフォーマンスなカスタムスクロールバー
///
/// 特徴:
/// 1. 画面上下10%に余白（マージン）を設け、中央80%の範囲内をスムーズに移動
/// 2. 通常時は幅6px、タップ・ドラッグ中は幅16pxに拡大＆シャドウ強調
/// 3. ValueNotifierによる局所リビルドで、親ツリーや長大リスト全体への不要な再描画負荷を完全ゼロ化
class CustomFastScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  final Color thumbColor;
  final double topMarginRatio;
  final double bottomMarginRatio;

  const CustomFastScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.thumbColor = const Color(0xFF5F9E98),
    this.topMarginRatio = 0.10,
    this.bottomMarginRatio = 0.10,
  });

  @override
  State<CustomFastScrollbar> createState() => _CustomFastScrollbarState();
}

class _CustomFastScrollbarState extends State<CustomFastScrollbar> {
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier<bool>(false);

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
    if (!widget.controller.hasClients) return;
    final pos = widget.controller.position;
    if (pos.maxScrollExtent <= 0) {
      _progressNotifier.value = 0.0;
      return;
    }
    final p = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    _progressNotifier.value = p;
  }

  void _handleDragUpdate(double localY, double totalHeight) {
    if (!widget.controller.hasClients) return;
    final topMargin = totalHeight * widget.topMarginRatio;
    final bottomMargin = totalHeight * widget.bottomMarginRatio;
    final usableHeight = totalHeight - topMargin - bottomMargin;
    if (usableHeight <= 0) return;

    final double progress = ((localY - topMargin) / usableHeight).clamp(0.0, 1.0);
    _progressNotifier.value = progress;

    final maxExtent = widget.controller.position.maxScrollExtent;
    if (maxExtent > 0) {
      widget.controller.jumpTo(progress * maxExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final topMargin = totalHeight * widget.topMarginRatio;
        final bottomMargin = totalHeight * widget.bottomMarginRatio;
        final trackHeight = (totalHeight - topMargin - bottomMargin).clamp(100.0, double.infinity);
        const double thumbHeight = 44.0;

        return Stack(
          children: [
            // リスト本体
            widget.child,

            // 右端のスクロールバー操作エリア（幅32pxでタップしやすい判定領域を確保）
            Positioned(
              top: topMargin,
              bottom: bottomMargin,
              right: 0,
              width: 32,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (details) {
                  _isDraggingNotifier.value = true;
                  _handleDragUpdate(details.localPosition.dy + topMargin, totalHeight);
                },
                onVerticalDragUpdate: (details) {
                  _handleDragUpdate(details.localPosition.dy + topMargin, totalHeight);
                },
                onVerticalDragEnd: (_) {
                  _isDraggingNotifier.value = false;
                },
                onVerticalDragCancel: () {
                  _isDraggingNotifier.value = false;
                },
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
                                duration: const Duration(milliseconds: 150),
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
                                            color: widget.thumbColor.withAlpha(100),
                                            blurRadius: 8,
                                            offset: const Offset(-1, 0),
                                            spreadRadius: 1,
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
