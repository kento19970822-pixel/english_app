import 'package:flutter/material.dart';

/// 単語帳上部 検索・フィルター・データ管理バー
class WordSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;
  final bool soundEnabled;
  final VoidCallback? onToggleSound;
  final int activeFilterCount;
  final VoidCallback onOpenFilter;
  final Future<void> Function() onSyncFlags;
  final Future<void> Function() onResetWordsDb;
  final Future<void> Function() onResetLearningData;
  final Color bgColor;
  final Color borderColor;
  final Color surfaceColor;
  final Color primaryColor;
  final Color textColor;
  final Color textSecondaryColor;

  const WordSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    this.onChanged,
    this.onSubmitted,
    required this.onClear,
    this.soundEnabled = true,
    this.onToggleSound,
    required this.activeFilterCount,
    required this.onOpenFilter,
    required this.onSyncFlags,
    required this.onResetWordsDb,
    required this.onResetLearningData,
    this.bgColor = const Color(0xFFF9F6F0),
    this.borderColor = const Color(0xFFE0D8C8),
    this.surfaceColor = const Color(0xFFEFEAE0),
    this.primaryColor = const Color(0xFF2E8B57),
    this.textColor = const Color(0xFF2C3E50),
    this.textSecondaryColor = const Color(0xFF7F8C8D),
  });

  @override
  State<WordSearchBar> createState() => _WordSearchBarState();
}

class _WordSearchBarState extends State<WordSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.bgColor,
      padding: const EdgeInsets.fromLTRB(14.0, 7.0, 10.0, 5.0),
      child: Row(
        children: [
          // 検索フィールド
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: widget.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.borderColor),
              ),
              child: TextField(
                controller: widget.searchController,
                focusNode: widget.searchFocusNode,
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(fontSize: 13.5, color: widget.textColor),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '英単語または和訳で検索 (Enterで実行)...',
                  hintStyle: TextStyle(color: widget.textSecondaryColor, fontSize: 12.5),
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search_rounded, size: 19, color: widget.textSecondaryColor),
                    onPressed: () {
                      widget.onSubmitted?.call(widget.searchController.text.trim());
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 38),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 38),
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 17, color: widget.textSecondaryColor),
                          onPressed: widget.onClear,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                ),
                onChanged: widget.onChanged,
                onSubmitted: (val) {
                  widget.onSubmitted?.call(val.trim());
                },
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 絞り込みフィルターボタン（バッジ付き・スリム）
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  widget.activeFilterCount > 0 ? Icons.filter_alt_rounded : Icons.tune_rounded,
                  color: widget.activeFilterCount > 0 ? widget.primaryColor : widget.textSecondaryColor,
                  size: 21,
                ),
                tooltip: '絞り込みフィルター',
                onPressed: widget.onOpenFilter,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              if (widget.activeFilterCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // データ管理ポップアップメニュー (3点ドット)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 20, color: widget.textSecondaryColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
            tooltip: 'データ管理・設定',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'sync_flags') {
                await widget.onSyncFlags();
              } else if (value == 'rebuild_db') {
                await _showConfirmDialog(
                  context,
                  title: '単語データベース再構築',
                  message: '全単語データをアセットから再インポートします。暗記ポイントやステータスは可能な限り保持されます。実行しますか？',
                  onConfirm: widget.onResetWordsDb,
                );
              } else if (value == 'reset_learning') {
                await _showConfirmDialog(
                  context,
                  title: '全単語の暗記フラグを一括クリア',
                  message: '単語帳の暗記チェック（暗記フラグ）を一括で未暗記に戻します。チャプター解放やスタンプ、学習記録は保持されます。実行しますか？',
                  isDestructive: true,
                  onConfirm: widget.onResetLearningData,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sync_flags',
                child: Row(
                  children: [
                    Icon(Icons.sync_rounded, size: 18, color: widget.primaryColor),
                    const SizedBox(width: 8),
                    const Text('80pt以上の単語を暗記済みに同期', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'rebuild_db',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text('単語DBをアセットから再構築', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_learning',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.orangeAccent),
                    SizedBox(width: 8),
                    Text('全単語の暗記フラグを一括クリア', style: TextStyle(fontSize: 13, color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDestructive = false,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('キャンセル', style: TextStyle(color: widget.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.redAccent : widget.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('実行する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onConfirm();
    }
  }
}
