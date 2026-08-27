import 'package:flutter/material.dart';

/// 単語帳上部 検索・フィルター・データ管理バー
class WordSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onChanged;
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
    required this.onChanged,
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
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(14.0, 7.0, 10.0, 5.0),
      child: Row(
        children: [
          // 検索フィールド（幅広拡大）
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(fontSize: 13.5, color: textColor),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '英単語または和訳で検索...',
                  hintStyle: TextStyle(color: textSecondaryColor, fontSize: 13.0),
                  prefixIcon: Icon(Icons.search_rounded, size: 19, color: textSecondaryColor),
                  prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 38),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 17, color: textSecondaryColor),
                          onPressed: onClear,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                ),
                onChanged: onChanged,
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
                  activeFilterCount > 0 ? Icons.filter_alt_rounded : Icons.tune_rounded,
                  color: activeFilterCount > 0 ? primaryColor : textSecondaryColor,
                  size: 21,
                ),
                tooltip: '絞り込みフィルター',
                onPressed: onOpenFilter,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: 1,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // データ管理ポップアップメニュー（スリム・右寄せ）
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textSecondaryColor, size: 21),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'sync_flags') {
                await onSyncFlags();
              } else if (value == 'reset_words') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('単語DBの再構築'),
                    content: const Text('assets/words.csv から全単語データを再取り込みします。\n学習進捗（定着度など）は維持されます。実行しますか？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('再構築する', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await onResetWordsDb();
                }
              } else if (value == 'reset_learning') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('学習データのリセット', style: TextStyle(color: Colors.red)),
                    content: const Text('すべての単語の定着度、覚えたフラグ、日別記録、スタンプ獲得状況が初期化されます。\nこの操作は取り消せません。本当によろしいですか？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('初期化する', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await onResetLearningData();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sync_flags',
                child: Row(
                  children: [
                    Icon(Icons.published_with_changes_rounded, size: 18, color: Color(0xFF2E8B57)),
                    SizedBox(width: 8),
                    Text('暗記フラグ再同期 (80pt未満解除)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_words',
                child: Row(
                  children: [
                    Icon(Icons.sync_rounded, size: 18, color: Color(0xFFD97736)),
                    SizedBox(width: 8),
                    Text('最新データでDBを再構築', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset_learning',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('学習進捗を初期化', style: TextStyle(fontSize: 13, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
