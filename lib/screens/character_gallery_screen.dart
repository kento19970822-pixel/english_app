// コード管理番号: VER-20260826-09
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/buddy_service.dart';
import '../widgets/pixel_character_widget.dart';

/// キャラクター図鑑画面 (F-12: 全チャプター1:1固有キャラクター・8大系統フィルター)
class CharacterGalleryScreen extends StatefulWidget {
  final AppDatabase database;
  final VoidCallback? onBack;
  final List<ChapterProgressesData>? initialProgresses;
  final Stamp? initialFavoriteStamp;

  const CharacterGalleryScreen({
    super.key,
    required this.database,
    this.onBack,
    this.initialProgresses,
    this.initialFavoriteStamp,
  });

  @override
  State<CharacterGalleryScreen> createState() => _CharacterGalleryScreenState();
}

class _CharacterGalleryScreenState extends State<CharacterGalleryScreen> {
  int _activeBuddyId = 0; // 0..373 (対応チャプター: _activeBuddyId + 1)
  Map<int, ChapterProgressesData> _chapterProgressesMap = {};
  bool _isLoading = true;
  Stamp? _favoriteStamp;
  CharacterCategory? _selectedCategoryFilter; // null = 全て
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

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
    _scrollController.addListener(_onScroll);

    if (widget.initialProgresses != null && widget.initialProgresses!.isNotEmpty) {
      _favoriteStamp = widget.initialFavoriteStamp;
      _chapterProgressesMap = {
        for (final cp in widget.initialProgresses!) cp.chapter: cp,
      };
      _isLoading = false;
    }
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 300;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadData() async {
    if (_chapterProgressesMap.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        widget.database.getFavoriteStamp(),
        widget.database.getAllChapterProgresses(),
      ]);
      final favStamp = results[0] as Stamp?;
      final progresses = results[1] as List<ChapterProgressesData>;

      if (mounted) {
        setState(() {
          _favoriteStamp = favStamp;
          _chapterProgressesMap = {
            for (final cp in progresses) cp.chapter: cp,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// チャプター進行状況からキャラクターの成長状態を厳格に判定 (O(1) 高速ルックアップ)
  CharacterGrowthState _getSpeciesGrowthState(int speciesId) {
    final chapter = speciesId + 1;
    final progress = _chapterProgressesMap[chapter];
    if (progress == null) return CharacterGrowthState.locked;
    return PixelCharacterWidget.stateFromRate(progress.memorizedRate, progress.isUnlocked);
  }

  void _setAsBuddy(int speciesId) {
    setState(() {
      _activeBuddyId = speciesId;
      BuddyService.instance.setSelectedSpeciesId(speciesId);
    });

    final species = getCharacterSpecies(speciesId + 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('相棒を「${species.japaneseName}（Ch.${species.chapter}）」に変更しました！'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSpecies = getCharacterSpecies(_activeBuddyId + 1);
    final activeGrowth = _getSpeciesGrowthState(_activeBuddyId);

    // フィルター適用後のチャプターリスト (1..374)
    final filteredChapters = List.generate(kTotalChapterCount, (i) => i + 1).where((chap) {
      if (_selectedCategoryFilter == null) return true;
      return CharacterCategory.fromChapter(chap) == _selectedCategoryFilter;
    }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _scrollToTop,
          child: const Text(
            'キャラクター図鑑',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: _primaryAccent,
              foregroundColor: Colors.white,
              elevation: 3,
              tooltip: '最上部へスクロール',
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryAccent))
          : SafeArea(
              child: Column(
                children: [
                  // 1. 固定上部セクション（相棒バナー ＆ 8系統フィルター）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 現在の相棒バナー
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _primaryAccent.withAlpha(120), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryAccent.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              PixelCharacterWidget(
                                speciesIndex: _activeBuddyId,
                                growthState: activeGrowth,
                                actionState: activeGrowth == CharacterGrowthState.locked
                                    ? CharacterActionState.idle
                                    : CharacterActionState.humming,
                                favoriteStamp: _favoriteStamp,
                                size: 58,
                                isInteractive: true,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                        Expanded(
                                          child: Text(
                                            activeGrowth == CharacterGrowthState.locked
                                                ? '？？？？？ (Ch.${activeSpecies.chapter})'
                                                : '${activeSpecies.japaneseName} (Ch.${activeSpecies.chapter})',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: _textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      activeGrowth == CharacterGrowthState.locked
                                          ? 'チャプター${activeSpecies.chapter}の単語を暗記して解放しよう！'
                                          : activeSpecies.description,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _textSecondary,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (_favoriteStamp != null && activeGrowth != CharacterGrowthState.locked) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                          const SizedBox(width: 3),
                                          Text(
                                            '胸バッジ: ${_favoriteStamp!.description}',
                                            style: const TextStyle(
                                              fontSize: 10,
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
                        const SizedBox(height: 8),

                        // 8大系統フィルター（横スクロール）
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: 'すべて (全$kTotalChapterCount体)',
                                isSelected: _selectedCategoryFilter == null,
                                onTap: () => setState(() => _selectedCategoryFilter = null),
                              ),
                              ...CharacterCategory.values.map((cat) {
                                final count = List.generate(kTotalChapterCount, (i) => i + 1)
                                    .where((chap) => CharacterCategory.fromChapter(chap) == cat)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _buildFilterChip(
                                    label: '${cat.icon} ${cat.label} ($count)',
                                    isSelected: _selectedCategoryFilter == cat,
                                    onTap: () => setState(() => _selectedCategoryFilter = cat),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 2. 図鑑スクロールエリア（高速インタラクティブスクロールバー付き）
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      thickness: 6.0,
                      radius: const Radius.circular(3),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: filteredChapters.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                      final chapter = filteredChapters[index];
                      final speciesId = chapter - 1;
                      final species = getCharacterSpecies(chapter);
                      final growth = _getSpeciesGrowthState(speciesId);
                      final isLocked = growth == CharacterGrowthState.locked;
                      final isCurrentBuddy = _activeBuddyId == speciesId;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(14),
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
                              speciesIndex: speciesId,
                              growthState: growth,
                              actionState: isLocked
                                  ? CharacterActionState.idle
                                  : CharacterActionState.walk,
                              favoriteStamp: isCurrentBuddy ? _favoriteStamp : null,
                              size: 50,
                            ),
                            const SizedBox(width: 12),

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
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isLocked ? Colors.grey : _textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ch.$chapter',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECEFF1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${species.category.icon} ${species.category.label}',
                                          style: const TextStyle(fontSize: 9, color: _textSecondary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isLocked
                                        ? 'Chapter $chapter の単語を学習・暗記しよう！'
                                        : species.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isLocked ? Colors.grey : _textSecondary,
                                    ),
                                  ),
                                  if (!isLocked) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '特徴: ${species.coreFeature}',
                                      style: const TextStyle(fontSize: 10, color: _primaryAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  const SizedBox(height: 5),

                                  // 形態ステータスバッジ
                                  _buildGrowthBadge(growth),
                                ],
                              ),
                            ),

                            // 相棒選択ボタン（解放済みのみ）
                            if (!isLocked) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: isCurrentBuddy
                                    ? null
                                    : () => _setAsBuddy(speciesId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryAccent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _primaryAccent.withAlpha(40),
                                  disabledForegroundColor: _primaryAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  isCurrentBuddy ? '相棒中' : '相棒にする',
                                  style: const TextStyle(
                                    fontSize: 10,
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
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primaryAccent : const Color(0xFFEFEAE0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primaryAccent : _borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : _textPrimary,
          ),
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
        label = '🔒 未解放 (0%)';
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
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
