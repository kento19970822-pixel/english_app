// コード管理番号: VER-20260824-17
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
      backgroundColor: _bgColor,
      appBar: AppBar(
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
                  ],
                ),
              ),
            ),
    );
  }

  /// ストリーク（連続プレイ日数）ヘッダーカード
  Widget _buildStreakHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '連続学習日数',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _textSecondary,
                ),
              ),
              Row(
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
                    '日連続',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
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

              return Container(
                decoration: BoxDecoration(
                  color: hasActivity
                      ? _primaryAccent.withAlpha(30)
                      : const Color(0xFFF7F4EB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasActivity
                        ? _primaryAccent
                        : Colors.transparent,
                    width: hasActivity ? 1.5 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasActivity
                                ? _primaryAccent
                                : _textPrimary,
                          ),
                        ),
                        if (hasActivity) ...[
                          const SizedBox(height: 1),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: Color(0xFF4CAF50),
                          ),
                          if (memorizedCount > 0)
                            Text(
                              '+$memorizedCount',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _primaryAccent,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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
