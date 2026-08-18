// コード管理番号: VER-20260818-04
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import 'game_screen.dart';

class ModeSelectScreen extends StatefulWidget {
  final AppDatabase database;
  final Function(bool isStarted)? onGameStateChanged;

  const ModeSelectScreen({
    super.key,
    required this.database,
    this.onGameStateChanged,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  String selectedMode = 'learning'; // 'learning' or 'challenge'
  int selectedLevel = 1;
  int selectedChapter = 1;

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          database: widget.database,
          onGameStateChanged: widget.onGameStateChanged,
          mode: selectedMode,
          initialLevel: selectedLevel,
          initialChapter: selectedChapter,
          autoStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'モード選択',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'プレイモードを選択',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      title: '学習モード',
                      subtitle: '章ごとの単語を集中学習',
                      icon: Icons.school,
                      modeKey: 'learning',
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeCard(
                      title: 'チャレンジ',
                      subtitle: '全単語からランダム出題',
                      icon: Icons.bolt,
                      modeKey: 'challenge',
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '難易度（レベル）選択',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('初級 (A1/A2)')),
                  ButtonSegment(value: 2, label: Text('中級 (B1/B2)')),
                  ButtonSegment(value: 3, label: Text('上級 (C1/C2)')),
                ],
                selected: {selectedLevel},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    selectedLevel = newSelection.first;
                  });
                },
              ),
              if (selectedMode == 'learning') ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'チャプター選択',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    DropdownButton<int>(
                      value: selectedChapter,
                      items: List.generate(10, (index) => index + 1)
                          .map(
                            (ch) => DropdownMenuItem(
                              value: ch,
                              child: Text('Chapter $ch'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedChapter = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: selectedMode == 'learning'
                      ? Colors.indigo
                      : Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _startGame,
                child: Text(
                  '${selectedMode == 'learning' ? '学習' : 'チャレンジ'}を開始',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String modeKey,
    required Color color,
  }) {
    final isSelected = selectedMode == modeKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = modeKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
