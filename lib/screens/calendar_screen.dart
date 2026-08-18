import 'package:flutter/material.dart';

import '../db/app_database.dart';

class CalendarScreen extends StatefulWidget {
  final AppDatabase database;

  const CalendarScreen({super.key, required this.database});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  Map<String, DailyRecord> _dailyRecordsMap = {};
  int _streakCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);

    final records = await widget.database.getDailyRecordsByMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final streak = await widget.database.calculateStreak();

    final Map<String, DailyRecord> map = {};
    for (final r in records) {
      map[r.dateStr] = r;
    }

    if (mounted) {
      setState(() {
        _dailyRecordsMap = map;
        _streakCount = streak;
        _isLoading = false;
      });
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('学習カレンダー'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    _buildStreakHeader(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildCalendarCard()),
                  ],
                ),
              ),
            ),
    );
  }

  /// ストリーク（連続プレイ日数）ヘッダーカード
  Widget _buildStreakHeader() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.orange.shade50,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.deepOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '連続学習日数',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_streakCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '日連続',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
    // 最大6行（42マス）として行数を計算
    final rowCount = (totalItems / 7).ceil();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          children: [
            // 月切替ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_focusedMonth.year}年 ${_focusedMonth.month}月',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
            const Divider(height: 8),
            // カレンダーグリッド（LayoutBuilderで高さを動的計算）
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const mainAxisSpacing = 4.0;
                  const crossAxisSpacing = 4.0;

                  // 利用可能な高さ・幅からマスの縦横比をレスポンシブ計算
                  final cellWidth =
                      (constraints.maxWidth - (crossAxisSpacing * 6)) / 7;
                  final cellHeight =
                      (constraints.maxHeight -
                          (mainAxisSpacing * (rowCount - 1))) /
                      rowCount;

                  // 万が一計算値が異常な場合のセーフティ
                  final calculatedRatio = (cellWidth > 0 && cellHeight > 0)
                      ? (cellWidth / cellHeight)
                      : 1.0;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio: calculatedRatio,
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

                      return Container(
                        decoration: BoxDecoration(
                          color: hasActivity
                              ? Colors.indigo.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: hasActivity
                                ? Colors.indigo.shade200
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hasActivity
                                    ? Colors.indigo
                                    : Colors.black87,
                              ),
                            ),
                            if (hasActivity) ...[
                              const SizedBox(height: 1),
                              Icon(
                                Icons.check_circle,
                                size: 11,
                                color: Colors.green.shade600,
                              ),
                              if (memorizedCount > 0)
                                Text(
                                  '+$memorizedCount',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
    Color color = Colors.black87;
    if (isSunday) color = Colors.red;
    if (isSaturday) color = Colors.blue;

    return Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
    );
  }
}
