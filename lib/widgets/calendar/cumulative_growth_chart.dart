// コード管理番号: VER-20260831-04
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/bouncy_scale_tap.dart';

/// 成長グラフの表示期間スパン (日 / 月 / 年)
enum GrowthSpan {
  daily('日', '30日間'),
  monthly('月', '12ヶ月'),
  yearly('年', '年間');

  final String label;
  final String description;
  const GrowthSpan(this.label, this.description);
}

/// 累計暗記単語数 ＆ 成長推移折れ線グラフ Widget (F-25)
class CumulativeGrowthChart extends StatefulWidget {
  final int totalMemorizedCount;
  final List<({DateTime date, int cumulativeCount, int dailyGain})> dailyHistory;
  final List<({DateTime date, int cumulativeCount, int dailyGain})> monthlyHistory;
  final List<({DateTime date, int cumulativeCount, int dailyGain})> yearlyHistory;
  final int totalAvailableWords;

  const CumulativeGrowthChart({
    super.key,
    required this.totalMemorizedCount,
    required this.dailyHistory,
    required this.monthlyHistory,
    required this.yearlyHistory,
    this.totalAvailableWords = 3000,
  });

  @override
  State<CumulativeGrowthChart> createState() => _CumulativeGrowthChartState();
}

class _CumulativeGrowthChartState extends State<CumulativeGrowthChart> {
  GrowthSpan _selectedSpan = GrowthSpan.daily;
  int? _selectedIndex; // タップ・ドラッグで選択中のデータポイントインデックス

  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _borderColor = Color(0xFFE5DEC9);

  List<({DateTime date, int cumulativeCount, int dailyGain})> get _currentHistory {
    switch (_selectedSpan) {
      case GrowthSpan.daily:
        return widget.dailyHistory;
      case GrowthSpan.monthly:
        return widget.monthlyHistory;
      case GrowthSpan.yearly:
        return widget.yearlyHistory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _currentHistory;
    final startCount = history.isNotEmpty ? history.first.cumulativeCount : 0;
    final endCount = history.isNotEmpty ? history.last.cumulativeCount : widget.totalMemorizedCount;
    final gainInPeriod = max(0, endCount - startCount);
    final percentOfTotal = widget.totalAvailableWords > 0
        ? (widget.totalMemorizedCount / widget.totalAvailableWords * 100).toStringAsFixed(1)
        : '0.0';

    String gainLabel = '+$gainInPeriod 語 (${_selectedSpan.description})';
    if (_selectedSpan == GrowthSpan.monthly && history.isNotEmpty) {
      final currentMonthGain = history.last.dailyGain;
      gainLabel = '今月 +$currentMonthGain 語 (+$gainInPeriod 語/1年)';
    } else if (_selectedSpan == GrowthSpan.yearly && history.isNotEmpty) {
      final currentYearGain = history.last.dailyGain;
      gainLabel = '今年 +$currentYearGain 語';
    }

    return Container(
      // カレンダーおよび月間推移カードと1pxの狂いもなく完全同期 (親Paddingに沿う)
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ヘッダー部: タイトル ＆ スパン切り替えチップ (日 / 月 / 年)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 18,
                  color: _primaryAccent,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '累計暗記単語数',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              // スパン選択チップ群 (日 / 月 / 年)
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: GrowthSpan.values.map((span) {
                    final isSelected = _selectedSpan == span;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: BouncyScaleTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedSpan = span;
                            _selectedIndex = null;
                          });
                        },
                        pressedScale: 0.92,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _primaryAccent.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1.5),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            span.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : _textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. HUD数値表記部: 累計単語数 ＆ 増加数 ＆ 進捗バー
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.totalMemorizedCount}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                  fontFamily: 'monospace',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '語 暗記達成',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              // 期間内増加バッジ
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          gainLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 進捗バー (全単語に対する暗記割合)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.totalAvailableWords > 0
                        ? (widget.totalMemorizedCount / widget.totalAvailableWords).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEFEAE0),
                    valueColor: const AlwaysStoppedAnimation<Color>(_primaryAccent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentOfTotal% / 全${widget.totalAvailableWords}語',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. 折れ線グラフ描画エリア (CustomPainter)
          SizedBox(
            height: 145,
            width: double.infinity,
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      '暗記データがありません',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth, history.length),
                        onHorizontalDragUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth, history.length),
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, 145),
                          painter: _GrowthChartPainter(
                            history: history,
                            span: _selectedSpan,
                            selectedIndex: _selectedIndex,
                            primaryColor: _primaryAccent,
                            textPrimaryColor: _textPrimary,
                            textSecondaryColor: _textSecondary,
                            gridColor: _borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 4. 下部ヒント
          const SizedBox(height: 6),
          const Center(
            child: Text(
              '※ グラフをタップすると各時点での累計暗記数を確認できます',
              style: TextStyle(
                fontSize: 10,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, double chartWidth, int dataCount) {
    if (dataCount == 0) return;
    if (dataCount == 1) {
      if (_selectedIndex != 0) {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = 0);
      }
      return;
    }
    const paddingLeft = 32.0;
    const paddingRight = 16.0;
    final effectiveWidth = chartWidth - paddingLeft - paddingRight;
    if (effectiveWidth <= 0) return;

    final x = (localPosition.dx - paddingLeft).clamp(0.0, effectiveWidth);
    final index = ((x / effectiveWidth) * (dataCount - 1)).round().clamp(0, dataCount - 1);

    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}

/// 折れ線グラフ CustomPainter
class _GrowthChartPainter extends CustomPainter {
  final List<({DateTime date, int cumulativeCount, int dailyGain})> history;
  final GrowthSpan span;
  final int? selectedIndex;
  final Color primaryColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color gridColor;

  _GrowthChartPainter({
    required this.history,
    required this.span,
    this.selectedIndex,
    required this.primaryColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    const double paddingTop = 22.0;
    const double paddingBottom = 22.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    // 最小値と最大値の算出
    final counts = history.map((e) => e.cumulativeCount).toList();
    int minCount = counts.reduce(min);
    int maxCount = counts.reduce(max);

    if (minCount == maxCount) {
      minCount = max(0, minCount - 5);
      maxCount = maxCount + 5;
    }
    final range = max(1, maxCount - minCount);

    // 1. Y軸グリッド線 & ラベル (3本: min, mid, max)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final ySteps = [minCount, ((minCount + maxCount) / 2).round(), maxCount];
    for (final val in ySteps) {
      final normY = 1.0 - ((val - minCount) / range);
      final y = paddingTop + normY * chartHeight;

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Y軸ラベル
      final textSpan = TextSpan(
        text: '$val',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textSecondaryColor,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 4, y - tp.height / 2));
    }

    // 2. 各データポイントの座標計算
    final points = <Offset>[];
    final count = history.length;
    for (int i = 0; i < count; i++) {
      final x = count == 1
          ? paddingLeft + chartWidth / 2
          : paddingLeft + (i / (count - 1)) * chartWidth;
      final normY = 1.0 - ((history[i].cumulativeCount - minCount) / range);
      final y = paddingTop + normY * chartHeight;
      points.add(Offset(x, y));
    }

    // 3. 面塗りグラデーション (Fill)
    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, paddingTop + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final cur = points[i];
        final midX = (prev.dx + cur.dx) / 2;
        fillPath.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
      }
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.35),
            primaryColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
      canvas.drawPath(fillPath, fillPaint);
    }

    // 4. なだらかな折れ線 (Stroke)
    if (points.length >= 2) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final cur = points[i];
        final midX = (prev.dx + cur.dx) / 2;
        linePath.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
      }

      final linePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);
    }

    // 5. 各データポイントの丸ドット
    final dotPaint = Paint()..color = Colors.white;
    final dotStrokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(p, 3.5, dotStrokePaint);
    }

    // 6. X軸日付ラベル
    final xLabelIndices = _calculateXLabelIndices(count);
    for (final idx in xLabelIndices) {
      if (idx >= count) continue;
      final p = points[idx];
      final d = history[idx].date;
      final label = _formatXAxisLabel(d, span);

      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: textSecondaryColor,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      double labelX = p.dx - tp.width / 2;
      if (idx == 0) labelX = paddingLeft;
      if (idx == count - 1) labelX = size.width - paddingRight - tp.width;

      tp.paint(canvas, Offset(labelX, size.height - paddingBottom + 4));
    }

    // 7. 選択中ポイントのツールチップ描画 (吹き出し)
    if (selectedIndex != null && selectedIndex! < points.length) {
      final p = points[selectedIndex!];
      final entry = history[selectedIndex!];
      final d = entry.date;
      final dateFormatted = _formatTooltipDate(d, span);
      final gainText = entry.dailyGain > 0 ? " (+${entry.dailyGain})" : "";
      final tooltipText = "$dateFormatted: ${entry.cumulativeCount}語$gainText";

      // 垂直ガイドライン
      final guidePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(p.dx, paddingTop),
        Offset(p.dx, paddingTop + chartHeight),
        guidePaint,
      );

      // 強調ハイライトドット
      canvas.drawCircle(p, 5.5, Paint()..color = primaryColor);
      canvas.drawCircle(p, 3.0, Paint()..color = Colors.white);

      // 吹き出し矩形
      final tp = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bubbleWidth = tp.width + 12;
      final bubbleHeight = tp.height + 6;
      double bubbleX = (p.dx - bubbleWidth / 2).clamp(paddingLeft, size.width - paddingRight - bubbleWidth);
      double bubbleY = p.dy - bubbleHeight - 8;
      if (bubbleY < 0) {
        bubbleY = p.dy + 8; // 上にはみ出る場合は下に表示
      }

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleX, bubbleY, bubbleWidth, bubbleHeight),
        const Radius.circular(6),
      );
      final bubblePaint = Paint()
        ..color = const Color(0xFF2C302E).withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, bubblePaint);

      tp.paint(canvas, Offset(bubbleX + 6, bubbleY + 3));
    }
  }

  List<int> _calculateXLabelIndices(int count) {
    if (count <= 1) return [0];
    if (count <= 3) return List.generate(count, (i) => i);
    if (span == GrowthSpan.monthly && count >= 6) {
      // 月表示: 4等分で均等表示
      return {0, (count * 0.33).floor(), (count * 0.66).floor(), count - 1}.toList()..sort();
    }
    return {0, (count / 2).floor(), count - 1}.toList()..sort();
  }

  String _formatXAxisLabel(DateTime d, GrowthSpan s) {
    switch (s) {
      case GrowthSpan.daily:
        return "${d.month}/${d.day}";
      case GrowthSpan.monthly:
        return "${d.month}月";
      case GrowthSpan.yearly:
        return "${d.year}年";
    }
  }

  String _formatTooltipDate(DateTime d, GrowthSpan s) {
    switch (s) {
      case GrowthSpan.daily:
        return "${d.month}/${d.day}";
      case GrowthSpan.monthly:
        return "${d.year}年${d.month}月";
      case GrowthSpan.yearly:
        return "${d.year}年";
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.span != span ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.primaryColor != primaryColor;
  }
}
