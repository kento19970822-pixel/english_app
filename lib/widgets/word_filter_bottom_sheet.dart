// コード管理番号: VER-20260827-FILTER-BOTTOM-SHEET
import 'package:flutter/material.dart';

class WordFilterState {
  final bool filterUnlearned;
  final bool filterFavorite;
  final String selectedCefr;
  final String selectedChapter;
  final String selectedAz;
  final String selectedCategory;

  const WordFilterState({
    this.filterUnlearned = false,
    this.filterFavorite = false,
    this.selectedCefr = 'ALL',
    this.selectedChapter = 'ALL',
    this.selectedAz = 'ALL',
    this.selectedCategory = 'ALL',
  });

  bool get hasActiveFilter {
    return filterUnlearned ||
        filterFavorite ||
        selectedCefr != 'ALL' ||
        selectedChapter != 'ALL' ||
        selectedAz != 'ALL' ||
        selectedCategory != 'ALL';
  }

  int get activeFilterCount {
    int count = 0;
    if (filterUnlearned) count++;
    if (filterFavorite) count++;
    if (selectedCefr != 'ALL') count++;
    if (selectedChapter != 'ALL') count++;
    if (selectedAz != 'ALL') count++;
    if (selectedCategory != 'ALL') count++;
    return count;
  }

  WordFilterState copyWith({
    bool? filterUnlearned,
    bool? filterFavorite,
    String? selectedCefr,
    String? selectedChapter,
    String? selectedAz,
    String? selectedCategory,
  }) {
    return WordFilterState(
      filterUnlearned: filterUnlearned ?? this.filterUnlearned,
      filterFavorite: filterFavorite ?? this.filterFavorite,
      selectedCefr: selectedCefr ?? this.selectedCefr,
      selectedChapter: selectedChapter ?? this.selectedChapter,
      selectedAz: selectedAz ?? this.selectedAz,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class WordFilterBottomSheet extends StatefulWidget {
  final WordFilterState initialFilter;
  final String sortMode;
  final List<String> availableCefr;
  final List<int> availableChapters;
  final Map<String, List<int>>? cefrToChapters;
  final List<String> availableAz;
  final List<String> availableCategories;
  final ValueChanged<WordFilterState> onApply;

  const WordFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.sortMode,
    required this.availableCefr,
    required this.availableChapters,
    this.cefrToChapters,
    required this.availableAz,
    required this.availableCategories,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required WordFilterState initialFilter,
    required String sortMode,
    required List<String> availableCefr,
    required List<int> availableChapters,
    Map<String, List<int>>? cefrToChapters,
    required List<String> availableAz,
    required List<String> availableCategories,
    required ValueChanged<WordFilterState> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WordFilterBottomSheet(
        initialFilter: initialFilter,
        sortMode: sortMode,
        availableCefr: availableCefr,
        availableChapters: availableChapters,
        cefrToChapters: cefrToChapters,
        availableAz: availableAz,
        availableCategories: availableCategories,
        onApply: onApply,
      ),
    );
  }

  @override
  State<WordFilterBottomSheet> createState() => _WordFilterBottomSheetState();
}

class _WordFilterBottomSheetState extends State<WordFilterBottomSheet> {
  late bool _filterUnlearned;
  late bool _filterFavorite;
  late String _selectedCefr;
  late String _selectedChapter;
  late String _selectedAz;
  late String _selectedCategory;

  static const _bgColor = Color(0xFFFBF7EE);
  static const _primaryAccent = Color(0xFF5F9E98);
  static const _textPrimary = Color(0xFF2C302E);
  static const _textSecondary = Color(0xFF6B726E);
  static const _borderColor = Color(0xFFE5DEC9);

  @override
  void initState() {
    super.initState();
    _filterUnlearned = widget.initialFilter.filterUnlearned;
    _filterFavorite = widget.initialFilter.filterFavorite;
    _selectedCefr = widget.initialFilter.selectedCefr;
    _selectedChapter = widget.initialFilter.selectedChapter;
    _selectedAz = widget.initialFilter.selectedAz;
    _selectedCategory = widget.initialFilter.selectedCategory;
  }

  List<int> get _currentAvailableChapters {
    if (_selectedCefr != 'ALL' &&
        widget.cefrToChapters != null &&
        widget.cefrToChapters!.containsKey(_selectedCefr)) {
      return widget.cefrToChapters![_selectedCefr]!;
    }
    return widget.availableChapters;
  }

  void _onCefrSelected(String cefr) {
    setState(() {
      _selectedCefr = cefr;
      final validChaps = _currentAvailableChapters;
      if (_selectedChapter != 'ALL') {
        final chapNum = int.tryParse(_selectedChapter);
        if (chapNum == null || !validChaps.contains(chapNum)) {
          _selectedChapter = 'ALL';
        }
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _filterUnlearned = false;
      _filterFavorite = false;
      _selectedCefr = 'ALL';
      _selectedChapter = 'ALL';
      _selectedAz = 'ALL';
      _selectedCategory = 'ALL';
    });
  }

  void _applyFilters() {
    widget.onApply(
      WordFilterState(
        filterUnlearned: _filterUnlearned,
        filterFavorite: _filterFavorite,
        selectedCefr: _selectedCefr,
        selectedChapter: _selectedChapter,
        selectedAz: _selectedAz,
        selectedCategory: _selectedCategory,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ドラッグハンドル
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textSecondary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ヘッダー（小画面でもオーバーフローしないレスポンシブRow）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '絞り込みフィルター',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16, color: _textSecondary),
                    label: const Text(
                      'すべてリセット',
                      style: TextStyle(fontSize: 12.5, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderColor),

            // フィルター設定スクロールエリア
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ステータス絞り込み（未暗記・お気に入り）
                    const Text(
                      '学習ステータス',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            label: '未暗記のみ',
                            icon: Icons.school_outlined,
                            isSelected: _filterUnlearned,
                            onTap: () => setState(() => _filterUnlearned = !_filterUnlearned),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFilterChip(
                            label: 'お気に入り',
                            icon: Icons.star_rounded,
                            isSelected: _filterFavorite,
                            onTap: () => setState(() => _filterFavorite = !_filterFavorite),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. CEFR 難易度レベル
                    const Text(
                      'CEFR 難易度レベル',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: '全て',
                          isSelected: _selectedCefr == 'ALL',
                          onTap: () => _onCefrSelected('ALL'),
                        ),
                        ...widget.availableCefr.map(
                          (cefr) => _buildChoiceChip(
                            label: cefr,
                            isSelected: _selectedCefr == cefr,
                            onTap: () => _onCefrSelected(cefr),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. チャプター指定
                    const Text(
                      'チャプター指定',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: (['ALL', ..._currentAvailableChapters.map((e) => e.toString())].contains(_selectedChapter))
                              ? _selectedChapter
                              : 'ALL',
                          isExpanded: true,
                          style: const TextStyle(fontSize: 14, color: _textPrimary, fontWeight: FontWeight.bold),
                          items: [
                            const DropdownMenuItem(value: 'ALL', child: Text('すべてのチャプター')),
                            ..._currentAvailableChapters.map(
                              (ch) => DropdownMenuItem(
                                value: ch.toString(),
                                child: Text('Chapter $ch'),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedChapter = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. 頭文字 (A-Z) 指定
                    const Text(
                      '頭文字 (A-Z) 指定',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildChoiceChip(
                          label: '全て',
                          isSelected: _selectedAz == 'ALL',
                          onTap: () => setState(() => _selectedAz = 'ALL'),
                        ),
                        ...widget.availableAz.map(
                          (letter) => _buildChoiceChip(
                            label: letter,
                            isSelected: _selectedAz == letter,
                            onTap: () => setState(() => _selectedAz = letter),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 5. カテゴリ指定
                    const Text(
                      'カテゴリ指定',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: '全て',
                          isSelected: _selectedCategory == 'ALL',
                          onTap: () => setState(() => _selectedCategory = 'ALL'),
                        ),
                        ...widget.availableCategories.map(
                          (cat) => _buildChoiceChip(
                            label: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () => setState(() => _selectedCategory = cat),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ボトム適用ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryAccent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _applyFilters,
                  child: const Text(
                    '条件を適用して表示',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryAccent.withAlpha(25) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryAccent : _borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? _primaryAccent : _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? _primaryAccent : _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryAccent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primaryAccent : _borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : _textPrimary,
          ),
        ),
      ),
    );
  }
}
