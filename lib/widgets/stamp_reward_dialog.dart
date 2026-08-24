// コード管理番号: VER-20260824-31
import 'package:flutter/material.dart';
import '../db/app_database.dart';
import 'pixel_stamp_widget.dart';
import '../screens/stamp_gallery_screen.dart';

/// スタンプ獲得演出モーダルダイアログ
class StampRewardDialog extends StatefulWidget {
  final Stamp stamp;
  final AppDatabase database;

  const StampRewardDialog({
    super.key,
    required this.stamp,
    required this.database,
  });

  static Future<void> show(BuildContext context, Stamp stamp, AppDatabase db) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StampRewardDialog(stamp: stamp, database: db),
    );
  }

  @override
  State<StampRewardDialog> createState() => _StampRewardDialogState();
}

class _StampRewardDialogState extends State<StampRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stamp = widget.stamp;
    final rarity = StampRarity.fromString(stamp.rarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: rarity == StampRarity.superRare
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFFE5DEC9),
              width: rarity == StampRarity.superRare ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: rarity == StampRarity.superRare
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // タイトルヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFD4B86A), size: 24),
                  const SizedBox(width: 6),
                  Text(
                    '本日のスタンプ獲得！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rarity.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.stars_rounded, color: Color(0xFFD4B86A), size: 24),
                ],
              ),
              const SizedBox(height: 16),

              // ドット絵スタンプ（弾む拡大アニメーション）
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: rarity.badgeBgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: rarity.color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: PixelStampWidget(
                    id: stamp.id,
                    name: stamp.name,
                    rarity: rarity,
                    paletteId: stamp.colorPaletteId,
                    patternId: stamp.patternId,
                    frameId: stamp.frameId,
                    effectId: stamp.effectId,
                    isUnlocked: true,
                    size: 110,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // レア度バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: rarity.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rarity.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // スタンプ名
              Text(
                stamp.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C302E),
                ),
              ),
              const SizedBox(height: 6),

              // 獲得条件・説明文
              if (stamp.description.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7EE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5DEC9)),
                  ),
                  child: Text(
                    stamp.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B726E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // カレンダー押印メッセージ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F9E98).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF5F9E98)),
                    SizedBox(width: 6),
                    Text(
                      '今日のカレンダーに押印されました！',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F9E98),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 操作ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B726E),
                        side: const BorderSide(color: Color(0xFFE5DEC9)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: const Text('図鑑を見る', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F9E98),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StampGalleryScreen(database: widget.database),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
