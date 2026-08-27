// コード管理番号: VER-20260824-39
import 'dart:math';
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../widgets/pixel_stamp_widget.dart';

class CalendarScreen extends StatefulWidget {
  final AppDatabase database;
  final VoidCallback? onBack;

  const CalendarScreen({super.key, required this.database, this.onBack});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  Map<String, DailyRecord> _dailyRecordsMap = {};
  Map<String, Stamp> _stampsMap = {};
  int _streakCount = 0;
  int _totalStudiedDays = 0;
  bool _isLoading = true;

  // 定数パステルカラー
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
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        widget.database.getDailyRecordsByMonth(
          _focusedMonth.year,
          _focusedMonth.month,
        ),
        widget.database.calculateStreak(),
        widget.database.calculateTotalStudiedDays(),
        widget.database.getAllStamps(),
      ]);

      final records = results[0] as List<DailyRecord>;
      final streak = results[1] as int;
      final totalDays = results[2] as int;
      final allStamps = results[3] as List<Stamp>;

      final Map<String, DailyRecord> map = {};
      for (final r in records) {
        map[r.dateStr] = r;
      }

      final Map<String, Stamp> stampMap = {
        for (final s in allStamps) s.id: s,
      };

      if (mounted) {
        setState(() {
          _dailyRecordsMap = map;
          _stampsMap = stampMap;
          _streakCount = streak;
          _totalStudiedDays = totalDays;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Calendar data load error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
        1,
      );
    });
    _loadCalendarData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        leading: (widget.onBack != null || Navigator.canPop(context))
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textPrimary),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: const Text(
          '学習カレンダー',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryAccent))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStreakHeader(),
                    const SizedBox(height: 12),
                    _buildCalendarCard(),
                    const SizedBox(height: 16),
                    _buildDailyMemorizedStatsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// ストリーク（連続プレイ日数）＆ 累計学習日数ヘッダーカード (F-15)
  Widget _buildStreakHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _secondaryAccent.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: _secondaryAccent,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '連続学習日数',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$_streakCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _secondaryAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '日連続プレイ中！',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 累計学習日数バッジ (F-15)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '累計学習日数',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalStudiedDays 日',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 月別カレンダーカード
  Widget _buildCalendarCard() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstDayOfWeek =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday %
        7; // 日曜起算

    final totalItems = daysInMonth + firstDayOfWeek;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 月切替ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22, color: _textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${_focusedMonth.year}年 ${_focusedMonth.month}月',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22, color: _textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 曜日ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayLabel('日', isSunday: true),
              _WeekdayLabel('月'),
              _WeekdayLabel('火'),
              _WeekdayLabel('水'),
              _WeekdayLabel('木'),
              _WeekdayLabel('金'),
              _WeekdayLabel('土', isSaturday: true),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 8),

          // カレンダーグリッド（固定childAspectRatio ＋ FittedBoxで確実にオーバーフロー防止）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5.0,
              crossAxisSpacing: 5.0,
              childAspectRatio: 1.0,
            ),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              if (index < firstDayOfWeek) {
                return const SizedBox.shrink();
              }

              final day = index - firstDayOfWeek + 1;
              final dateStr =
                  '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final record = _dailyRecordsMap[dateStr];

              final hasActivity =
                  record != null &&
                  (record.playedCount > 0 || record.memorizedCount > 0);
              final memorizedCount = record?.memorizedCount ?? 0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = min(constraints.maxWidth, constraints.maxHeight);
                  // セルサイズに応じてスタンプサイズを動的調整（確実なオーバーフロー防止）
                  final stampSize = max(14.0, cellSize * 0.50);
                  final dayFontSize = max(9.0, cellSize * 0.18);
                  final badgeFontSize = max(7.5, cellSize * 0.13);

                  return Container(
                    decoration: BoxDecoration(
                      color: hasActivity
                          ? _primaryAccent.withAlpha(30)
                          : const Color(0xFFF7F4EB),
                      borderRadius: BorderRadius.circular(cellSize > 60 ? 12 : 8),
                      border: Border.all(
                        color: hasActivity
                            ? _primaryAccent
                            : Colors.transparent,
                        width: hasActivity ? 1.5 : 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 日付番号 (上部左寄せ)
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 2.0, top: 0.0),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: dayFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: hasActivity
                                      ? _primaryAccent
                                      : _textPrimary,
                                ),
                              ),
                            ),
                          ),

                          // 中央: 堂々と大きく表示されるスタンプ（FittedBoxで安全に縮小フィット）
                          Expanded(
                            child: Center(
                              child: hasActivity
                                  ? FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: (record.appliedStampId != null && _stampsMap.containsKey(record.appliedStampId!))
                                          ? Builder(
                                              builder: (context) {
                                                final s = _stampsMap[record.appliedStampId]!;
                                                return PixelStampWidget(
                                                  id: s.id,
                                                  name: s.name,
                                                  rarity: StampRarity.fromString(s.rarity),
                                                  paletteId: s.colorPaletteId,
                                                  patternId: s.patternId,
                                                  frameId: s.frameId,
                                                  effectId: s.effectId,
                                                  isUnlocked: true,
                                                  size: stampSize,
                                                );
                                              },
                                            )
                                          : Icon(
                                              Icons.check_circle_rounded,
                                              size: stampSize * 0.8,
                                              color: const Color(0xFF4CAF50),
                                            ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),

                          // 下部: 暗記数バッジ (あれば)
                          if (hasActivity && memorizedCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: _primaryAccent.withAlpha(40),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '+$memorizedCount',
                                    style: TextStyle(
                                      fontSize: badgeFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryAccent,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// 日ごとの新規暗記数・達成推移を視覚化したカード (F-15)
  Widget _buildDailyMemorizedStatsCard() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    int totalMemorizedInMonth = 0;
    int activeDaysCount = 0;
    int maxDailyMemorized = 0;
    final List<Map<String, dynamic>> dailyStats = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dateStr = date.toIso8601String().split('T')[0];
      final record = _dailyRecordsMap[dateStr];
      final memCount = record?.memorizedCount ?? 0;
      final playCount = record?.playedCount ?? 0;

      if (memCount > 0) {
        totalMemorizedInMonth += memCount;
        activeDaysCount++;
        if (memCount > maxDailyMemorized) {
          maxDailyMemorized = memCount;
        }
      }

      dailyStats.add({
        'day': day,
        'date': date,
        'dateStr': dateStr,
        'memorizedCount': memCount,
        'playedCount': playCount,
      });
    }

    final activeDays = dailyStats.where((d) => (d['memorizedCount'] as int) > 0 || (d['playedCount'] as int) > 0).toList()
      ..sort((a, b) => (b['day'] as int).compareTo(a['day'] as int));

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: _primaryAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                '${_focusedMonth.month}月の新規暗記数推移',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // サマリーチップ
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Column(
                    children: [
                      const Text('新規暗記合計', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '$totalMemorizedInMonth 語',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: Column(
                    children: [
                      const Text('暗記達成日数', style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '$activeDaysCount 日',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFBF360C)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCE93D8)),
                  ),
                  child: Column(
                    children: [
                      const Text('1日最高記録', style: TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '$maxDailyMemorized 語',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 視覚的日別バーチャート
          const Text(
            '日別新規暗記グラフ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F2E7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(daysInMonth, (index) {
                    final day = index + 1;
                    final stat = dailyStats[index];
                    final count = stat['memorizedCount'] as int;
                    final maxH = (constraints.maxHeight - 26).clamp(0.0, double.infinity);
                    final barHeight = maxDailyMemorized > 0 && count > 0
                        ? (count / maxDailyMemorized * maxH).clamp(6.0, maxH)
                        : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (count > 0)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 10),
                            Container(
                              height: barHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: count > 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                day % 5 == 1 || day == daysInMonth ? '$day' : '·',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: day % 5 == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 日別詳細ログリスト
          if (activeDays.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.emoji_events_outlined, color: Colors.grey, size: 32),
                  SizedBox(height: 6),
                  Text(
                    'この月の新規暗記記録はまだありません。\nゲームをクリアして新しい単語を暗記しよう！',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              '日別暗記・学習履歴',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...activeDays.take(10).map((stat) {
              final date = stat['date'] as DateTime;
              final mem = stat['memorizedCount'] as int;
              final play = stat['playedCount'] as int;
              final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
              final wStr = weekdays[date.weekday - 1];

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Text(
                      '${date.month}/${date.day}($wStr)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: date.weekday == 7
                            ? Colors.red.shade600
                            : (date.weekday == 6 ? Colors.blue.shade600 : _textPrimary),
                      ),
                    ),
                    const Spacer(),
                    if (mem > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              '+$mem 語 暗記',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text('暗記 0語', style: TextStyle(fontSize: 11, color: _textSecondary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEBE9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'プレイ $play回',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final bool isSunday;
  final bool isSaturday;

  const _WeekdayLabel(
    this.label, {
    this.isSunday = false,
    this.isSaturday = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFF6B726E);
    if (isSunday) color = Colors.red.shade400;
    if (isSaturday) color = Colors.blue.shade400;

    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
