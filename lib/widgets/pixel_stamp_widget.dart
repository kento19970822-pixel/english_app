// コード管理番号: VER-20260824-29
import 'dart:math';
import 'package:flutter/material.dart';

/// スタンプのレア度
enum StampRarity {
  normal,
  rare,
  superRare;

  static StampRarity fromString(String val) {
    switch (val.toLowerCase()) {
      case 'rare':
        return StampRarity.rare;
      case 'super_rare':
      case 'superrare':
      case 'sr':
        return StampRarity.superRare;
      default:
        return StampRarity.normal;
    }
  }

  String get label {
    switch (this) {
      case StampRarity.normal:
        return 'Normal';
      case StampRarity.rare:
        return 'Rare';
      case StampRarity.superRare:
        return 'Super Rare';
    }
  }

  Color get color {
    switch (this) {
      case StampRarity.normal:
        return const Color(0xFF5F9E98); // エメラルド
      case StampRarity.rare:
        return const Color(0xFF4A7BD0); // サファイアブルー
      case StampRarity.superRare:
        return const Color(0xFFD4AF37); // ゴールド
    }
  }

  Color get badgeBgColor {
    switch (this) {
      case StampRarity.normal:
        return const Color(0xFFE8F4F2);
      case StampRarity.rare:
        return const Color(0xFFEBF1FD);
      case StampRarity.superRare:
        return const Color(0xFFFDF7E2);
    }
  }
}

/// プロシージャルドット絵スタンプ描画ウィジェット
class PixelStampWidget extends StatelessWidget {
  final String id;
  final String name;
  final StampRarity rarity;
  final int paletteId;
  final int patternId;
  final int frameId;
  final int effectId;
  final bool isUnlocked;
  final bool isFavorite;
  final double size;
  final VoidCallback? onTap;

  const PixelStampWidget({
    super.key,
    required this.id,
    required this.name,
    this.rarity = StampRarity.normal,
    this.paletteId = 0,
    this.patternId = 0,
    this.frameId = 0,
    this.effectId = 0,
    this.isUnlocked = true,
    this.isFavorite = false,
    this.size = 64.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelStampPainter(
          rarity: rarity,
          paletteId: paletteId,
          patternId: patternId,
          frameId: frameId,
          effectId: effectId,
          isUnlocked: isUnlocked,
        ),
      ),
    );

    if (isFavorite && isUnlocked && size >= 36) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFDF9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFD4B86A),
                size: 14,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }
}

/// スタンプ描画カスタムペインター
class _PixelStampPainter extends CustomPainter {
  final StampRarity rarity;
  final int paletteId;
  final int patternId;
  final int frameId;
  final int effectId;
  final bool isUnlocked;

  _PixelStampPainter({
    required this.rarity,
    required this.paletteId,
    required this.patternId,
    required this.frameId,
    required this.effectId,
    required this.isUnlocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. カラーパレットの選定
    final palette = _getPalette(paletteId, rarity, isUnlocked);

    // 2. スタンプの影（ドロップシャドウ）
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isUnlocked ? 0.08 : 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.08, w * 0.9, h * 0.9),
        Radius.circular(w * 0.2),
      ),
      shadowPaint,
    );

    // 3. スタンプ外枠・背景の描画
    _drawFrameAndBackground(canvas, size, palette);

    // 4. 装飾エフェクトの描画 (Rare / SR)
    if (isUnlocked) {
      _drawEffects(canvas, size, palette);
    }

    // 5. 16x16 モチーフのピクセル描画
    _drawMotif(canvas, size, palette);

    // 6. 未解放時の「?」マークとロックオーバーレイ
    if (!isUnlocked) {
      _drawLockedOverlay(canvas, size);
    }
  }

  /// 外枠およびスタンプ背景の描画
  void _drawFrameAndBackground(Canvas canvas, Size size, _StampPalette palette) {
    final w = size.width;
    final h = size.height;
    final pad = w * 0.06;
    final innerRect = Rect.fromLTWH(pad, pad, w - pad * 2, h - pad * 2);

    final bgPaint = Paint()
      ..color = palette.background
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = palette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.055)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fId = frameId % 6;

    if (fId == 0) {
      // 0: クラシック丸枠
      final radius = (w - pad * 2) / 2;
      final center = Offset(w / 2, h / 2);
      canvas.drawCircle(center, radius, bgPaint);
      canvas.drawCircle(center, radius, borderPaint);
    } else if (fId == 1) {
      // 1: 角丸スクエア枠
      final rrect = RRect.fromRectAndRadius(innerRect, Radius.circular(w * 0.22));
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);
    } else if (fId == 2) {
      // 2: 切手ギザギザ枠 (Perforated Postage Stamp)
      final rrect = RRect.fromRectAndRadius(innerRect, Radius.circular(w * 0.12));
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);

      // ギザギザノッチ（スタンプの穿孔）
      final notchPaint = Paint()
        ..color = const Color(0xFFFBF7EE) // アプリ背景色で穴をあける
        ..style = PaintingStyle.fill;
      final notchR = max(1.2, w * 0.04);
      const notchCount = 5;
      for (int i = 1; i < notchCount; i++) {
        final x = innerRect.left + (innerRect.width / notchCount) * i;
        canvas.drawCircle(Offset(x, innerRect.top), notchR, notchPaint);
        canvas.drawCircle(Offset(x, innerRect.bottom), notchR, notchPaint);
        final y = innerRect.top + (innerRect.height / notchCount) * i;
        canvas.drawCircle(Offset(innerRect.left, y), notchR, notchPaint);
        canvas.drawCircle(Offset(innerRect.right, y), notchR, notchPaint);
      }
    } else if (fId == 3) {
      // 3: 二重線リボン枠 (Rare 二重線)
      final rrect = RRect.fromRectAndRadius(innerRect, Radius.circular(w * 0.18));
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);

      final innerBorder = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + w * 0.06, pad + h * 0.06, w - (pad + w * 0.06) * 2, h - (pad + h * 0.06) * 2),
        Radius.circular(w * 0.12),
      );
      final thinPaint = Paint()
        ..color = palette.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, w * 0.025);
      canvas.drawRRect(innerBorder, thinPaint);
    } else if (fId == 4) {
      // 4: 王冠エンブレム枠 (Super Rare 豪華八角形・王冠)
      final rrect = RRect.fromRectAndRadius(innerRect, Radius.circular(w * 0.28));
      canvas.drawRRect(rrect, bgPaint);

      // ゴールド二重枠
      canvas.drawRRect(rrect, borderPaint);
      final innerGold = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + w * 0.05, pad + h * 0.05, w - (pad + w * 0.05) * 2, h - (pad + h * 0.05) * 2),
        Radius.circular(w * 0.22),
      );
      final goldPaint = Paint()
        ..color = palette.highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, w * 0.035);
      canvas.drawRRect(innerGold, goldPaint);
    } else {
      // 5: 太陽光線・星型バッジ枠
      final radius = (w - pad * 2) / 2;
      final center = Offset(w / 2, h / 2);
      canvas.drawCircle(center, radius, bgPaint);
      canvas.drawCircle(center, radius, borderPaint);

      // 外周のドット飾り
      final dotPaint = Paint()
        ..color = palette.accent
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 8; i++) {
        final angle = (i * pi / 4);
        final dx = center.dx + cos(angle) * (radius - w * 0.06);
        final dy = center.dy + sin(angle) * (radius - w * 0.06);
        canvas.drawCircle(Offset(dx, dy), max(1.0, w * 0.03), dotPaint);
      }
    }
  }

  /// 装飾エフェクト（星粒子、集中線、キラキラ）
  void _drawEffects(Canvas canvas, Size size, _StampPalette palette) {
    final w = size.width;
    final h = size.height;
    final eff = effectId % 5;

    final starPaint = Paint()
      ..color = palette.accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    if (eff == 1 || eff == 3) {
      // 星粒子（四隅のキラキラスター）
      _drawSparkle(canvas, Offset(w * 0.24, h * 0.24), w * 0.08, starPaint);
      _drawSparkle(canvas, Offset(w * 0.76, h * 0.26), w * 0.06, starPaint);
      _drawSparkle(canvas, Offset(w * 0.22, h * 0.74), w * 0.06, starPaint);
      _drawSparkle(canvas, Offset(w * 0.76, h * 0.74), w * 0.08, starPaint);
    }

    if (eff == 2 || eff == 3) {
      // 集中線 / シャイン
      final rayPaint = Paint()
        ..color = palette.highlight.withValues(alpha: 0.35)
        ..strokeWidth = max(1.0, w * 0.02)
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < 6; i++) {
        final angle = i * pi / 3;
        final x1 = w / 2 + cos(angle) * (w * 0.32);
        final y1 = h / 2 + sin(angle) * (h * 0.32);
        final x2 = w / 2 + cos(angle) * (w * 0.40);
        final y2 = h / 2 + sin(angle) * (h * 0.40);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
      }
    }

    if (eff == 4) {
      // 月桂樹のドット小枝
      final leafPaint = Paint()
        ..color = palette.accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 4; i++) {
        final lx = w * (0.2 + i * 0.06);
        final ly = h * (0.8 - i * 0.03);
        canvas.drawCircle(Offset(lx, ly), max(1.0, w * 0.035), leafPaint);

        final rx = w * (0.8 - i * 0.06);
        final ry = h * (0.8 - i * 0.03);
        canvas.drawCircle(Offset(rx, ry), max(1.0, w * 0.035), leafPaint);
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double s, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - s);
    path.lineTo(center.dx + s * 0.3, center.dy - s * 0.3);
    path.lineTo(center.dx + s, center.dy);
    path.lineTo(center.dx + s * 0.3, center.dy + s * 0.3);
    path.lineTo(center.dx, center.dy + s);
    path.lineTo(center.dx - s * 0.3, center.dy + s * 0.3);
    path.lineTo(center.dx - s, center.dy);
    path.lineTo(center.dx - s * 0.3, center.dy - s * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 16x16 モチーフのピクセル描画（正確な重心センタリング）
  void _drawMotif(Canvas canvas, Size size, _StampPalette palette) {
    final matrix = _getPatternMatrix(patternId % 24);
    final w = size.width;
    final h = size.height;

    // モチーフの有効ピクセル範囲（バウンディングボックス）を計算
    int minCol = 16, maxCol = -1, minRow = 16, maxRow = -1;
    for (int r = 0; r < 16; r++) {
      for (int c = 0; c < 16; c++) {
        if (matrix[r][c] != 0) {
          if (c < minCol) minCol = c;
          if (c > maxCol) maxCol = c;
          if (r < minRow) minRow = r;
          if (r > maxRow) maxRow = r;
        }
      }
    }

    if (maxCol < minCol || maxRow < minRow) return;

    final motifSize = w * 0.56;
    final pixelSize = motifSize / 16;

    // バウンディングボックスの中心をスタンプの中心 (w/2, h/2) に完全に一致させる
    final centerCol = (minCol + maxCol + 1) / 2.0;
    final centerRow = (minRow + maxRow + 1) / 2.0;
    final startX = (w / 2) - (centerCol * pixelSize);
    final startY = (h / 2) - (centerRow * pixelSize);

    final pMain = Paint()
      ..color = palette.main
      ..style = PaintingStyle.fill;
    final pLight = Paint()
      ..color = palette.highlight
      ..style = PaintingStyle.fill;
    final pShadow = Paint()
      ..color = palette.shadow
      ..style = PaintingStyle.fill;
    final pAccent = Paint()
      ..color = palette.accent
      ..style = PaintingStyle.fill;
    final pWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pBlack = Paint()
      ..color = isUnlocked ? const Color(0xFF2C302E) : palette.main
      ..style = PaintingStyle.fill;

    for (int row = 0; row < 16; row++) {
      for (int col = 0; col < 16; col++) {
        final val = matrix[row][col];
        if (val == 0) continue;

        Paint currentPaint = pMain;
        if (isUnlocked) {
          switch (val) {
            case 1:
              currentPaint = pMain;
              break;
            case 2:
              currentPaint = pLight;
              break;
            case 3:
              currentPaint = pShadow;
              break;
            case 4:
              currentPaint = pAccent;
              break;
            case 5:
              currentPaint = pWhite;
              break;
            case 6:
              currentPaint = pBlack;
              break;
            default:
              currentPaint = pMain;
          }
        } else {
          // シルエット時
          currentPaint = pShadow;
        }

        final px = startX + col * pixelSize;
        final py = startY + row * pixelSize;
        canvas.drawRect(
          Rect.fromLTWH(px, py, pixelSize + 0.3, pixelSize + 0.3),
          currentPaint,
        );
      }
    }
  }

  /// 未解放時の「?」マークとロック表示
  void _drawLockedOverlay(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 中央に？マークをポップに描画
    final tp = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: w * 0.34,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFFDF9).withValues(alpha: 0.85),
          fontFamily: 'monospace',
          shadows: const [
            Shadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _PixelStampPainter oldDelegate) {
    return oldDelegate.rarity != rarity ||
        oldDelegate.paletteId != paletteId ||
        oldDelegate.patternId != patternId ||
        oldDelegate.frameId != frameId ||
        oldDelegate.effectId != effectId ||
        oldDelegate.isUnlocked != isUnlocked;
  }
}

/// スタンプ配色定義クラス
class _StampPalette {
  final Color main;
  final Color highlight;
  final Color shadow;
  final Color accent;
  final Color background;
  final Color border;

  const _StampPalette({
    required this.main,
    required this.highlight,
    required this.shadow,
    required this.accent,
    required this.background,
    required this.border,
  });
}

_StampPalette _getPalette(int id, StampRarity rarity, bool isUnlocked) {
  if (!isUnlocked) {
    // シルエット時（アンティークなダークグレー）
    return const _StampPalette(
      main: Color(0xFF6B726E),
      highlight: Color(0xFF888F8C),
      shadow: Color(0xFF424745),
      accent: Color(0xFF555B58),
      background: Color(0xFFE5DEC9),
      border: Color(0xFF9E998B),
    );
  }

  // レア度別の豊富な配色パレット
  switch (id % 16) {
    case 0: // エメラルド・ミント (Normal)
      return const _StampPalette(
        main: Color(0xFF5F9E98),
        highlight: Color(0xFF91CBC5),
        shadow: Color(0xFF386C67),
        accent: Color(0xFFECA882),
        background: Color(0xFFF0F9F8),
        border: Color(0xFF5F9E98),
      );
    case 1: // サクラ・ピンク (Normal)
      return const _StampPalette(
        main: Color(0xFFE58A9E),
        highlight: Color(0xFFF7BDCB),
        shadow: Color(0xFFA85165),
        accent: Color(0xFF5F9E98),
        background: Color(0xFFFDF2F5),
        border: Color(0xFFE58A9E),
      );
    case 2: // アンバー・オレンジ (Normal)
      return const _StampPalette(
        main: Color(0xFFECA882),
        highlight: Color(0xFFF6CEB8),
        shadow: Color(0xFFB57049),
        accent: Color(0xFF5F9E98),
        background: Color(0xFFFDF6F0),
        border: Color(0xFFECA882),
      );
    case 3: // オーシャン・スカイ (Normal)
      return const _StampPalette(
        main: Color(0xFF5B92E5),
        highlight: Color(0xFF96BBF5),
        shadow: Color(0xFF335FA6),
        accent: Color(0xFFFFAE42),
        background: Color(0xFFF0F5FD),
        border: Color(0xFF5B92E5),
      );
    case 4: // ラベンダー・ドリーム (Normal)
      return const _StampPalette(
        main: Color(0xFF9A82D4),
        highlight: Color(0xFFC7B8EE),
        shadow: Color(0xFF674EA3),
        accent: Color(0xFFFF8B94),
        background: Color(0xFFF7F4FD),
        border: Color(0xFF9A82D4),
      );
    case 5: // フォレスト・ハーブ (Normal)
      return const _StampPalette(
        main: Color(0xFF6AA866),
        highlight: Color(0xFF9ED49B),
        shadow: Color(0xFF3E753A),
        accent: Color(0xFFECA882),
        background: Color(0xFFF2F8F1),
        border: Color(0xFF6AA866),
      );
    case 6: // カフェ・モカ (Normal)
      return const _StampPalette(
        main: Color(0xFF9C7A5E),
        highlight: Color(0xFFC7AB93),
        shadow: Color(0xFF694C35),
        accent: Color(0xFFD4AF37),
        background: Color(0xFFFAF6F2),
        border: Color(0xFF9C7A5E),
      );
    case 7: // サニー・レモン (Normal)
      return const _StampPalette(
        main: Color(0xFFD8A82A),
        highlight: Color(0xFFF3D06B),
        shadow: Color(0xFF916E14),
        accent: Color(0xFF5F9E98),
        background: Color(0xFFFDF9EE),
        border: Color(0xFFD8A82A),
      );
    case 8: // ベリー・バイオレット (Rare)
      return const _StampPalette(
        main: Color(0xFF8A4BAA),
        highlight: Color(0xFFD39CEE),
        shadow: Color(0xFF55286F),
        accent: Color(0xFFFFD700),
        background: Color(0xFFF8F0FD),
        border: Color(0xFF8A4BAA),
      );
    case 9: // ロイヤル・サファイア (Rare)
      return const _StampPalette(
        main: Color(0xFF3252A8),
        highlight: Color(0xFF8CA8F5),
        shadow: Color(0xFF1B2F6E),
        accent: Color(0xFFFFD700),
        background: Color(0xFFEEF4FD),
        border: Color(0xFF3252A8),
      );
    case 10: // クリムゾン・ルビー (Rare)
      return const _StampPalette(
        main: Color(0xFFB83248),
        highlight: Color(0xFFF2899A),
        shadow: Color(0xFF751525),
        accent: Color(0xFFFFD700),
        background: Color(0xFFFDF0F2),
        border: Color(0xFFB83248),
      );
    case 11: // ゴールデン・ヴィンテージ (Rare)
      return const _StampPalette(
        main: Color(0xFFC49226),
        highlight: Color(0xFFF5CF6B),
        shadow: Color(0xFF825D11),
        accent: Color(0xFF4EA596),
        background: Color(0xFFFDF8EB),
        border: Color(0xFFC49226),
      );
    case 12: // ホログラフィック・プリズム (Super Rare)
      return const _StampPalette(
        main: Color(0xFF6A38B8),
        highlight: Color(0xFFFF85A1),
        shadow: Color(0xFF3D1978),
        accent: Color(0xFF00E5FF),
        background: Color(0xFFF5EEFD),
        border: Color(0xFFD4AF37),
      );
    case 13: // マジェスティック・ゴールド (Super Rare)
      return const _StampPalette(
        main: Color(0xFFD4AF37),
        highlight: Color(0xFFFFEA88),
        shadow: Color(0xFF8C711C),
        accent: Color(0xFFC92A2A),
        background: Color(0xFFFDF8E4),
        border: Color(0xFFD4AF37),
      );
    case 14: // サイバー・オーロラ (Super Rare)
      return const _StampPalette(
        main: Color(0xFF00C9A7),
        highlight: Color(0xFF845EC2),
        shadow: Color(0xFF007560),
        accent: Color(0xFFFF6F91),
        background: Color(0xFFEDFCF8),
        border: Color(0xFF00C9A7),
      );
    default: // インペリアル・ダイヤモンド (Super Rare)
      return const _StampPalette(
        main: Color(0xFF4B7BEC),
        highlight: Color(0xFFA5C8FF),
        shadow: Color(0xFF2647A0),
        accent: Color(0xFFFFD700),
        background: Color(0xFFF0F5FD),
        border: Color(0xFFD4AF37),
      );
  }
}

/// 16x16 ピクセルマトリクスの定義（24種類のモチーフパターン）
List<List<int>> _getPatternMatrix(int patternId) {
  // 0: 空白, 1: メイン, 2: ハイライト, 3: シャドウ, 4: アクセント, 5: 白, 6: 黒
  switch (patternId) {
    case 0: // 0: ヒヨコ (Chick)
      return [
        [0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 6, 2, 2, 2, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 4, 4, 4, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 2, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 1, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0],
        [0, 1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 3, 3, 3, 2, 2, 2, 2, 2, 2, 3, 1, 0, 0, 0],
        [0, 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 4, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 4, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 1: // 1: ネコ (Cat)
      return [
        [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0],
        [0, 1, 2, 1, 0, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0],
        [0, 1, 4, 2, 1, 1, 1, 1, 1, 1, 2, 4, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [1, 2, 6, 2, 2, 2, 2, 2, 2, 2, 2, 6, 2, 1, 0, 0],
        [1, 2, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 2, 1, 0, 0],
        [1, 6, 2, 2, 6, 2, 4, 4, 2, 6, 2, 2, 6, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 3, 3, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 2: // 2: イヌ (Dog)
      return [
        [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
        [0, 1, 3, 3, 1, 1, 1, 1, 1, 1, 3, 3, 1, 0, 0, 0],
        [0, 1, 3, 3, 2, 2, 2, 2, 2, 2, 3, 3, 1, 0, 0, 0],
        [0, 1, 3, 1, 2, 2, 2, 2, 2, 2, 1, 3, 1, 0, 0, 0],
        [0, 0, 1, 2, 2, 6, 2, 2, 6, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 5, 6, 6, 5, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 1, 2, 5, 5, 6, 6, 5, 5, 2, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 5, 5, 4, 4, 5, 5, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 1, 4, 4, 1, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 3: // 3: フクロウ博士 (Wise Owl)
      return [
        [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 2, 5, 5, 6, 2, 2, 2, 2, 6, 5, 5, 2, 1, 0, 0],
        [1, 2, 5, 6, 6, 4, 4, 4, 4, 6, 6, 5, 2, 1, 0, 0],
        [1, 2, 5, 5, 6, 4, 4, 4, 4, 6, 5, 5, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 3, 1, 2, 5, 2, 5, 2, 5, 2, 1, 3, 1, 0, 0, 0],
        [1, 3, 1, 2, 2, 5, 2, 5, 2, 2, 1, 3, 1, 0, 0, 0],
        [1, 3, 1, 2, 5, 2, 5, 2, 5, 2, 1, 3, 1, 0, 0, 0],
        [0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 4: // 4: ライオン (Lion)
      return [
        [0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0],
        [0, 4, 4, 1, 4, 4, 4, 4, 4, 4, 1, 4, 4, 0, 0, 0],
        [4, 4, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 4, 4, 0, 0],
        [4, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 4, 0, 0],
        [4, 1, 2, 6, 2, 2, 2, 2, 2, 2, 6, 2, 1, 4, 0, 0],
        [4, 1, 2, 2, 2, 2, 6, 6, 2, 2, 2, 2, 1, 4, 0, 0],
        [0, 4, 1, 2, 2, 5, 6, 6, 5, 2, 2, 1, 4, 0, 0, 0],
        [0, 4, 4, 1, 2, 2, 3, 3, 2, 2, 1, 4, 4, 0, 0, 0],
        [0, 0, 4, 4, 1, 1, 1, 1, 1, 1, 4, 4, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 5: // 5: ウサギ (Rabbit)
      return [
        [0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
        [0, 1, 2, 4, 1, 0, 0, 0, 1, 4, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 4, 1, 0, 0, 0, 1, 4, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 4, 1, 0, 0, 0, 1, 4, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 1, 1, 1, 1, 1, 2, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [1, 2, 6, 2, 2, 2, 2, 2, 2, 2, 6, 2, 1, 0, 0, 0],
        [1, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 4, 2, 2, 2, 3, 3, 2, 2, 2, 2, 4, 1, 0, 0, 0],
        [0, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 6: // 6: ペンギン (Penguin)
      return [
        [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 3, 5, 6, 3, 3, 6, 5, 3, 1, 0, 0, 0, 0],
        [0, 0, 1, 3, 5, 5, 4, 4, 5, 5, 3, 1, 0, 0, 0, 0],
        [0, 0, 1, 3, 3, 4, 4, 4, 4, 3, 3, 1, 0, 0, 0, 0],
        [0, 1, 3, 3, 4, 4, 4, 4, 4, 4, 3, 3, 1, 0, 0, 0],
        [1, 3, 3, 5, 5, 4, 4, 4, 4, 5, 5, 3, 3, 1, 0, 0],
        [1, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 1, 0, 0],
        [1, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 1, 0, 0],
        [1, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 1, 0, 0],
        [0, 1, 3, 5, 5, 5, 5, 5, 5, 5, 5, 3, 1, 0, 0, 0],
        [0, 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 4, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 7: // 7: 開いた本 (Open Book)
      return [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0],
        [0, 1, 5, 5, 5, 5, 5, 1, 5, 5, 5, 5, 5, 1, 0, 0],
        [1, 5, 6, 6, 6, 6, 5, 1, 5, 6, 6, 6, 6, 5, 1, 0],
        [1, 5, 5, 5, 5, 5, 5, 1, 5, 5, 5, 5, 5, 5, 1, 0],
        [1, 5, 6, 6, 6, 6, 5, 1, 5, 6, 6, 6, 6, 5, 1, 0],
        [1, 5, 5, 5, 5, 5, 5, 1, 5, 5, 5, 5, 5, 5, 1, 0],
        [1, 5, 6, 6, 6, 6, 5, 1, 5, 6, 6, 6, 6, 5, 1, 0],
        [1, 5, 5, 5, 5, 5, 5, 1, 5, 5, 5, 5, 5, 5, 1, 0],
        [0, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 8: // 8: 王冠 (Crown)
      return [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 4, 0, 0, 0, 0, 4, 0, 0, 0, 0, 4, 0, 0, 0],
        [0, 4, 2, 4, 0, 0, 4, 2, 4, 0, 0, 4, 2, 4, 0, 0],
        [0, 0, 4, 0, 0, 0, 0, 4, 0, 0, 0, 0, 4, 0, 0, 0],
        [0, 1, 2, 1, 0, 0, 1, 2, 1, 0, 0, 1, 2, 1, 0, 0],
        [0, 1, 2, 2, 1, 0, 1, 2, 1, 0, 1, 2, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 1, 1, 2, 1, 1, 2, 2, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [0, 1, 2, 4, 2, 2, 4, 2, 4, 2, 2, 4, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0],
        [0, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 9: // 9: トロフィー (Trophy)
      return [
        [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 0, 0],
        [1, 2, 1, 2, 2, 2, 4, 4, 2, 2, 2, 2, 1, 2, 1, 0],
        [1, 2, 1, 2, 2, 4, 4, 4, 4, 2, 2, 2, 1, 2, 1, 0],
        [1, 2, 1, 2, 2, 2, 4, 4, 2, 2, 2, 2, 1, 2, 1, 0],
        [0, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 0, 0],
        [0, 0, 0, 1, 3, 2, 2, 2, 2, 2, 3, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 10: // 10: 輝く星 (Glowing Star)
      return [
        [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 1, 1, 2, 2, 2, 1, 1, 2, 2, 1, 0, 0],
        [1, 2, 2, 1, 0, 0, 1, 2, 1, 0, 0, 1, 2, 2, 1, 0],
        [1, 2, 1, 0, 0, 0, 1, 2, 1, 0, 0, 0, 1, 2, 1, 0],
        [1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 11: // 11: ハート (Heart)
      return [
        [0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 1, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0],
        [1, 2, 5, 2, 2, 2, 1, 1, 2, 2, 2, 2, 2, 1, 0, 0],
        [1, 2, 5, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 12: // 12: ひらめき電球 (Idea Lightbulb)
      return [
        [0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 2, 2, 2, 2, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 5, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 5, 5, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 4, 4, 4, 4, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 4, 4, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 6, 6, 6, 6, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 6, 6, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 13: // 13: 時計 (Clock)
      return [
        [0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 2, 2, 2, 2, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 2, 2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [1, 2, 6, 2, 2, 2, 6, 6, 6, 6, 2, 2, 6, 1, 0, 0],
        [1, 2, 2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 3, 3, 3, 3, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 14: // 14: リンゴ (Apple)
      return [
        [0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 0, 0, 0, 0, 0],
        [1, 2, 5, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [1, 2, 5, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 15: // 15: 双葉 (Sprout)
      return [
        [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 2, 2, 1, 0, 0, 0, 1, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 1, 2, 2, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 1, 0, 0],
        [0, 0, 1, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 0, 0, 1, 1, 1, 4, 4, 1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0],
        [0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 16: // 16: 情熱の炎 (Burning Flame)
      return [
        [0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 2, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 4, 2, 2, 4, 0, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 4, 2, 2, 2, 4, 4, 2, 4, 0, 0, 0, 0, 0],
        [0, 0, 4, 2, 2, 2, 2, 2, 2, 2, 4, 0, 0, 0, 0, 0],
        [0, 0, 4, 2, 2, 5, 2, 2, 2, 2, 4, 0, 0, 0, 0, 0],
        [0, 4, 2, 2, 5, 5, 5, 2, 2, 2, 2, 4, 0, 0, 0, 0],
        [0, 4, 2, 2, 5, 5, 5, 2, 2, 2, 2, 4, 0, 0, 0, 0],
        [0, 4, 2, 2, 2, 5, 2, 2, 2, 2, 2, 4, 0, 0, 0, 0],
        [0, 0, 4, 2, 2, 2, 2, 2, 2, 2, 4, 0, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 2, 2, 2, 4, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 17: // 17: ダイヤ (Diamond Gem)
      return [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 0, 0, 0, 0],
        [0, 1, 2, 5, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [1, 2, 5, 5, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 18: // 18: 四つ葉のクローバー (Clover)
      return [
        [0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
        [0, 1, 2, 2, 1, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 1, 1, 0, 1, 1, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 1, 1, 2, 2, 1, 2, 2, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 4, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 1, 1, 2, 2, 4, 4, 4, 2, 2, 1, 1, 0, 0, 0, 0],
        [1, 2, 2, 1, 2, 4, 4, 4, 2, 1, 2, 2, 1, 0, 0, 0],
        [1, 2, 2, 1, 2, 2, 4, 2, 2, 1, 2, 2, 1, 0, 0, 0],
        [0, 1, 1, 0, 1, 2, 4, 2, 1, 0, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 4, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 1, 4, 1, 2, 2, 1, 0, 0, 0, 0, 0],
        [0, 1, 2, 2, 1, 0, 4, 0, 1, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 1, 1, 0, 0, 4, 0, 0, 1, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 19: // 19: 鳳凰・ドラゴンの翼 (Mythical Wings - SR)
      return [
        [0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0],
        [4, 2, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 2, 4, 0],
        [4, 2, 2, 4, 0, 0, 0, 4, 0, 0, 0, 4, 2, 2, 4, 0],
        [0, 4, 2, 2, 4, 0, 4, 2, 4, 0, 4, 2, 2, 4, 0, 0],
        [0, 0, 4, 2, 2, 4, 2, 2, 2, 4, 2, 2, 4, 0, 0, 0],
        [0, 0, 0, 4, 2, 2, 2, 2, 2, 2, 2, 4, 0, 0, 0, 0],
        [0, 4, 4, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 4, 0, 0],
        [4, 2, 2, 2, 2, 4, 2, 2, 2, 4, 2, 2, 2, 2, 4, 0],
        [4, 2, 2, 2, 4, 2, 2, 4, 2, 2, 4, 2, 2, 2, 4, 0],
        [0, 4, 4, 4, 2, 2, 4, 4, 4, 2, 2, 4, 4, 4, 0, 0],
        [0, 0, 0, 0, 4, 2, 2, 4, 2, 2, 4, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 2, 2, 2, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 4, 2, 4, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 20: // 20: 輝く宝箱 (Treasure Chest - SR)
      return [
        [0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 2, 2, 2, 2, 2, 4, 4, 0, 0, 0, 0],
        [0, 0, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [1, 2, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 2, 2, 1, 0],
        [1, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 1, 0],
        [1, 4, 2, 5, 2, 5, 2, 5, 2, 5, 2, 5, 4, 2, 1, 0],
        [1, 1, 1, 1, 1, 1, 4, 4, 1, 1, 1, 1, 1, 1, 1, 0],
        [1, 3, 3, 3, 3, 3, 4, 4, 3, 3, 3, 3, 3, 3, 1, 0],
        [1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0],
        [1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 21: // 21: 聖杯 (Holy Grail - SR)
      return [
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 5, 2, 2, 4, 4, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 5, 5, 4, 4, 4, 4, 2, 2, 2, 1, 0, 0, 0],
        [0, 1, 2, 2, 2, 2, 4, 4, 2, 2, 2, 2, 1, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 4, 4, 4, 4, 2, 1, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    case 22: // 22: 大彗星 (Comet - SR)
      return [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 2, 4, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 4, 4, 2, 2, 4, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 4, 4, 2, 2, 2, 4, 0, 0, 0, 0, 0],
        [0, 0, 0, 4, 4, 2, 2, 2, 2, 4, 0, 0, 0, 0, 0, 0],
        [0, 0, 4, 2, 2, 2, 2, 2, 4, 0, 0, 0, 0, 0, 0, 0],
        [0, 4, 2, 2, 1, 1, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0],
        [4, 2, 2, 1, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [4, 2, 1, 2, 5, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 4, 1, 2, 5, 5, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];

    default: // 23: 知恵の鍵 (Key of Wisdom)
      return [
        [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 4, 4, 4, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 4, 0, 4, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 2, 4, 4, 4, 2, 2, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 1, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 1, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 4, 1, 1, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 4, 4, 4, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 4, 1, 1, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 4, 4, 4, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
  }
}
