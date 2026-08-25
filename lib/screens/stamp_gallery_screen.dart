// コード管理番号: VER-20260824-32
import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../services/stamp_service.dart';
import '../widgets/pixel_stamp_widget.dart';

/// スタンプ図鑑画面 (F-12)
class StampGalleryScreen extends StatefulWidget {
  final AppDatabase database;
  final VoidCallback? onBack;

  const StampGalleryScreen({super.key, required this.database, this.onBack});

  @override
  State<StampGalleryScreen> createState() => _StampGalleryScreenState();
}

class _StampGalleryScreenState extends State<StampGalleryScreen> {
  late StampService _stampService;
  List<Stamp> _allStamps = [];
  int _selectedPhase = 1;
  int _maxPhase = 1;
  String _selectedFilter = 'all'; // all, unlocked, locked, normal, rare, super_rare
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stampService = StampService(database: widget.database);
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    setState(() => _isLoading = true);
    try {
      await _stampService.ensureInitialized();
      final all = await widget.database.getAllStamps();
      final maxP = await widget.database.getMaxStampPhase();

      if (mounted) {
        setState(() {
          _allStamps = all;
          _maxPhase = maxP > 0 ? maxP : 1;
          if (_selectedPhase > _maxPhase) _selectedPhase = _maxPhase;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Stamp gallery data load error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Stamp> get _currentPhaseStamps {
    return _allStamps.where((s) => s.phase == _selectedPhase).toList();
  }

  List<Stamp> get _filteredStamps {
    final list = _currentPhaseStamps;
    switch (_selectedFilter) {
      case 'unlocked':
        return list.where((s) => s.isUnlocked).toList();
      case 'locked':
        return list.where((s) => !s.isUnlocked).toList();
      case 'normal':
        return list.where((s) => s.rarity == 'normal').toList();
      case 'rare':
        return list.where((s) => s.rarity == 'rare').toList();
      case 'super_rare':
        return list.where((s) => s.rarity == 'super_rare').toList();
      case 'all':
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseStamps = _currentPhaseStamps;
    final totalInPhase = phaseStamps.length;
    final unlockedInPhase = phaseStamps.where((s) => s.isUnlocked).length;
    final rate = totalInPhase > 0 ? (unlockedInPhase / totalInPhase) : 0.0;
    final canPhaseUp = rate >= 0.8;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        title: const Text(
          'スタンプ図鑑',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C302E),
          ),
        ),
        backgroundColor: const Color(0xFFFFFDF9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF2C302E)),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Phase切り替えドロップダウン
          if (_maxPhase > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedPhase,
                  dropdownColor: const Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5F9E98)),
                  items: List.generate(_maxPhase, (index) {
                    final p = index + 1;
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        'Phase $p',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2C302E),
                        ),
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPhase = val);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5F9E98)))
          : SafeArea(
              child: Column(
                children: [
                  // 1. Phase進捗 & 図鑑拡張 (Phase UP) ヘッダー
                  _buildPhaseHeader(
                    unlockedCount: unlockedInPhase,
                    totalCount: totalInPhase,
                    rate: rate,
                    canPhaseUp: canPhaseUp,
                  ),

                  // 2. フィルターチップバー
                  _buildFilterBar(phaseStamps),

                  // 3. スタンプグリッド一覧
                  Expanded(
                    child: _buildStampGrid(),
                  ),
                ],
              ),
            ),
    );
  }

  /// Phase進捗ヘッダーカード
  Widget _buildPhaseHeader({
    required int unlockedCount,
    required int totalCount,
    required double rate,
    required bool canPhaseUp,
  }) {
    final percentage = (rate * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F9E98),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Phase $_selectedPhase',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '図鑑進捗: $unlockedCount / $totalCount 個 ($percentage%)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C302E),
                ),
              ),
              const Spacer(),
              if (canPhaseUp)
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text(
                    'Phase UP!',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _showPhaseUpDialog,
                ),
            ],
          ),
          const SizedBox(height: 10),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFE8D8),
              valueColor: AlwaysStoppedAnimation<Color>(
                canPhaseUp ? const Color(0xFFD4AF37) : const Color(0xFF5F9E98),
              ),
            ),
          ),
          if (!canPhaseUp && totalCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '※ 80%獲得 (${(totalCount * 0.8).ceil()}個) で次のPhaseが解放可能！',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF888F8C)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// フィルターチップバー
  Widget _buildFilterBar(List<Stamp> phaseStamps) {
    final filters = [
      {'key': 'all', 'label': 'すべて', 'count': phaseStamps.length},
      {'key': 'unlocked', 'label': '獲得済', 'count': phaseStamps.where((s) => s.isUnlocked).length},
      {'key': 'locked', 'label': '未獲得', 'count': phaseStamps.where((s) => !s.isUnlocked).length},
      {'key': 'normal', 'label': 'Normal', 'count': phaseStamps.where((s) => s.rarity == 'normal').length},
      {'key': 'rare', 'label': 'Rare', 'count': phaseStamps.where((s) => s.rarity == 'rare').length},
      {'key': 'super_rare', 'label': 'SR', 'count': phaseStamps.where((s) => s.rarity == 'super_rare').length},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['key'];
          return ChoiceChip(
            label: Text('${f['label']} (${f['count']})'),
            selected: isSelected,
            selectedColor: const Color(0xFF5F9E98),
            backgroundColor: const Color(0xFFFFFDF9),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF6B726E),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? const Color(0xFF5F9E98) : const Color(0xFFE5DEC9),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = f['key'] as String);
              }
            },
          );
        },
      ),
    );
  }

  /// スタンプグリッド一覧
  Widget _buildStampGrid() {
    final stamps = _filteredStamps;
    if (stamps.isEmpty) {
      return const Center(
        child: Text(
          '該当するスタンプがありません',
          style: TextStyle(color: Color(0xFF888F8C), fontSize: 13),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 画面幅に応じて列数を動的調整 (スマホ: 4列、デスクトップ: 5〜6列)
        final crossAxisCount = constraints.maxWidth > 600 ? 6 : (constraints.maxWidth > 400 ? 4 : 3);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.82,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: stamps.length,
          itemBuilder: (context, index) {
            final s = stamps[index];
            final rarity = StampRarity.fromString(s.rarity);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showStampDetailDialog(s),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: s.isFavorite
                        ? const Color(0xFFD4AF37)
                        : (s.isUnlocked ? const Color(0xFFE5DEC9) : const Color(0xFFD5CEBC)),
                    width: s.isFavorite ? 2.0 : 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: PixelStampWidget(
                          id: s.id,
                          name: s.name,
                          rarity: rarity,
                          paletteId: s.colorPaletteId,
                          patternId: s.patternId,
                          frameId: s.frameId,
                          effectId: s.effectId,
                          isUnlocked: s.isUnlocked,
                          isFavorite: s.isFavorite,
                          size: 58,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        s.isUnlocked ? s.name : '???',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: s.isUnlocked ? const Color(0xFF2C302E) : const Color(0xFF888F8C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// スタンプ詳細ダイアログ
  void _showStampDetailDialog(Stamp stamp) {
    final rarity = StampRarity.fromString(stamp.rarity);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isFav = stamp.isFavorite;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: rarity == StampRarity.superRare
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFFE5DEC9),
                    width: rarity == StampRarity.superRare ? 2.0 : 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // スタンプ大画面表示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: stamp.isUnlocked ? rarity.badgeBgColor : const Color(0xFFF0EBE0),
                        shape: BoxShape.circle,
                      ),
                      child: PixelStampWidget(
                        id: stamp.id,
                        name: stamp.name,
                        rarity: rarity,
                        paletteId: stamp.colorPaletteId,
                        patternId: stamp.patternId,
                        frameId: stamp.frameId,
                        effectId: stamp.effectId,
                        isUnlocked: stamp.isUnlocked,
                        size: 96,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // レア度バッジ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: rarity.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        rarity.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // スタンプ名
                    Text(
                      stamp.isUnlocked ? stamp.name : '??? （未解放）',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C302E),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 条件・説明文
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF7EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5DEC9)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stamp.isUnlocked ? '【獲得条件】' : '【解放ヒント】',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stamp.isUnlocked ? const Color(0xFF5F9E98) : const Color(0xFFECA882),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stamp.description.isNotEmpty ? stamp.description : '毎日の学習で獲得可能',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B726E),
                            ),
                          ),
                          if (stamp.isUnlocked && stamp.unlockedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '獲得日: ${stamp.unlockedAt!.year}/${stamp.unlockedAt!.month}/${stamp.unlockedAt!.day}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF888F8C),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 相棒お気に入り設定ボタン（獲得済の場合のみ）
                    if (stamp.isUnlocked)
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton.icon(
                          icon: Icon(
                            isFav ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 18,
                            color: isFav ? const Color(0xFFD4AF37) : const Color(0xFF6B726E),
                          ),
                          label: Text(
                            isFav ? '相棒のお気に入りに設定中' : '相棒のお気に入りに設定',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isFav ? const Color(0xFFD4AF37) : const Color(0xFF2C302E),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isFav ? const Color(0xFFD4AF37) : const Color(0xFFE5DEC9),
                              width: isFav ? 1.5 : 1.0,
                            ),
                            backgroundColor: isFav ? const Color(0xFFFFF9E6) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await widget.database.setFavoriteStamp(stamp.id);
                            await _loadStamps();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 10),

                    // 閉じるボタン
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F9E98),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Phase UP 実行確認ダイアログ
  void _showPhaseUpDialog() {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 24),
            SizedBox(width: 8),
            Text(
              '図鑑拡張 (Phase UP)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF2C302E),
              ),
            ),
          ],
        ),
        content: Text(
          'Phase $_selectedPhase のスタンプを80%以上獲得しました！\n\n図鑑を拡張して、新しいPhase ${_maxPhase + 1} のスタンプ（20個）を追加しますか？',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B726E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('キャンセル', style: TextStyle(color: Color(0xFF888F8C))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final newPhase = await _stampService.executePhaseUp();
              await _loadStamps();

              if (mounted) {
                setState(() => _selectedPhase = newPhase);
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF5F9E98),
                    content: Text('✨ Phase $newPhase の図鑑が解放されました！（+20個）'),
                  ),
                );
              }
            },
            child: const Text('拡張する！', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
