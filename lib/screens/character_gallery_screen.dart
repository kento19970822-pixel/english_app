// コード管理番号: VER-20260824-48
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../widgets/pixel_character_widget.dart';

/// キャラクター図鑑画面 (F-12)
class CharacterGalleryScreen extends StatefulWidget {
  final AppDatabase database;

  const CharacterGalleryScreen({super.key, required this.database});

  @override
  State<CharacterGalleryScreen> createState() => _CharacterGalleryScreenState();
}

class _CharacterGalleryScreenState extends State<CharacterGalleryScreen> {
  bool _isLoading = true;
  Stamp? _favoriteStamp;
  List<ChapterProgressesData> _chapterProgresses = [];
  int _activeBuddyId = 0;

  // 定数パステルカラー
  static const Color _bgColor = Color(0xFFFBF7EE);
  static const Color _cardColor = Color(0xFFFFFDF9);
  static const Color _primaryAccent = Color(0xFF5F9E98);
  static const Color _textPrimary = Color(0xFF2C302E);
  static const Color _textSecondary = Color(0xFF6B726E);
  static const Color _borderColor = Color(0xFFE5DEC9);

  @override
  void initState() {
    super.initState();
    _activeBuddyId = BuddyService.instance.selectedSpeciesId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final favStamp = await widget.database.getFavoriteStamp();
      final progresses = await widget.database.getAllChapterProgresses();

      if (mounted) {
        setState(() {
          _favoriteStamp = favStamp;
          _chapterProgresses = progresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 各種族の最高成長状態をチャプター進行状況から算出
  CharacterGrowthState _getSpeciesGrowthState(int speciesId) {
    if (_chapterProgresses.isEmpty) return CharacterGrowthState.healthy;

    // 種族に対応するチャプター群（例: speciesId 0 -> Chapter 1, 13, 25...）
    final matchingChapters = _chapterProgresses.where(
      (cp) => (cp.chapter - 1) % 12 == speciesId,
    ).toList();

    if (matchingChapters.isEmpty) {
      // 該当チャプターがまだ存在しない場合は初期解放種族（0: ヒヨコ）はhealthy、それ以外はlocked
      return speciesId == 0 ? CharacterGrowthState.healthy : CharacterGrowthState.locked;
    }

    bool hasUnlocked = matchingChapters.any((cp) => cp.isUnlocked);
    if (!hasUnlocked && speciesId != 0) {
      return CharacterGrowthState.locked;
    }

    double maxRate = 0.0;
    for (final cp in matchingChapters) {
      if (cp.memorizedRate > maxRate) {
        maxRate = cp.memorizedRate;
      }
    }

    if (maxRate >= 80.0) return CharacterGrowthState.evolved;
    if (maxRate >= 50.0) return CharacterGrowthState.healthy;
    if (maxRate > 0.0 || hasUnlocked || speciesId == 0) return CharacterGrowthState.healthy;
    return CharacterGrowthState.locked;
  }

  void _setAsBuddy(int speciesId) {
    setState(() {
      _activeBuddyId = speciesId;
      BuddyService.instance.setSelectedSpeciesId(speciesId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('相棒を「${kCharacterSpeciesList[speciesId].japaneseName}」に変更しました！'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSpecies = kCharacterSpeciesList[_activeBuddyId];
    final activeGrowth = _getSpeciesGrowthState(_activeBuddyId);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'キャラクター図鑑',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryAccent))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                children: [
                  // 1. 現在の相棒バナー
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _primaryAccent.withAlpha(120), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryAccent.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        PixelCharacterWidget(
                          speciesIndex: _activeBuddyId,
                          growthState: activeGrowth == CharacterGrowthState.locked
                              ? CharacterGrowthState.healthy
                              : activeGrowth,
                          actionState: CharacterActionState.humming,
                          favoriteStamp: _favoriteStamp,
                          size: 72,
                          isInteractive: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _primaryAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '現在の相棒',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    activeSpecies.japaneseName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeSpecies.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                  height: 1.3,
                                ),
                              ),
                              if (_favoriteStamp != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '胸バッジ: ${_favoriteStamp!.description}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. 図鑑リスト
                  const Text(
                    '章ドットキャラクター一覧 (全12種)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kCharacterSpeciesList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final species = kCharacterSpeciesList[index];
                      final growth = _getSpeciesGrowthState(index);
                      final isLocked = growth == CharacterGrowthState.locked;
                      final isCurrentBuddy = _activeBuddyId == index;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrentBuddy ? _primaryAccent : _borderColor,
                            width: isCurrentBuddy ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // キャラクタープレビュー
                            PixelCharacterWidget(
                              speciesIndex: index,
                              growthState: growth,
                              actionState: isLocked
                                  ? CharacterActionState.idle
                                  : CharacterActionState.walk,
                              favoriteStamp: isCurrentBuddy ? _favoriteStamp : null,
                              size: 54,
                            ),
                            const SizedBox(width: 14),

                            // 情報エリア
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isLocked ? '？？？？？' : species.japaneseName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isLocked ? Colors.grey : _textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isLocked ? '' : species.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isLocked
                                        ? 'チャプターを進めて解放しよう！'
                                        : species.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isLocked ? Colors.grey : _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // 形態ステータスバッジ
                                  _buildGrowthBadge(growth),
                                ],
                              ),
                            ),

                            // 相棒選択ボタン
                            if (!isLocked) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: isCurrentBuddy
                                    ? null
                                    : () => _setAsBuddy(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryAccent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _primaryAccent.withAlpha(40),
                                  disabledForegroundColor: _primaryAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isCurrentBuddy ? '相棒中' : '相棒にする',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildGrowthBadge(CharacterGrowthState growth) {
    String label;
    Color bg;
    Color textColor;

    switch (growth) {
      case CharacterGrowthState.locked:
        label = '🔒 未解放';
        bg = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case CharacterGrowthState.lowHealth:
        label = '🥀 元気ない (1〜49%)';
        bg = const Color(0xFFFFF3E0);
        textColor = Colors.deepOrange;
        break;
      case CharacterGrowthState.healthy:
        label = '😊 元気 (50〜79%)';
        bg = const Color(0xFFE8F5E9);
        textColor = Colors.green.shade800;
        break;
      case CharacterGrowthState.evolved:
        label = '🌟 進化形態 (80%以上)';
        bg = const Color(0xFFEDE7F6);
        textColor = const Color(0xFF6A1B9A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
