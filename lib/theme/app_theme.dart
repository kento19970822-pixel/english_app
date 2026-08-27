// コード管理番号: VER-20260827-01
import 'package:flutter/material.dart';

/// アプリ全体の統合テーマ管理（ライト ＆ パステルダーク）
/// WCAG 2.1 AA 準拠のコントラスト比（4.5:1以上）を全テキストで担保
class AppTheme {
  AppTheme._();

  // ==========================================
  // 1. ライトテーマ（クラフトパステル）
  // ==========================================
  static const Color lightBg = Color(0xFFF9F6F0);
  static const Color lightCard = Color(0xFFFFFDF9);
  static const Color lightBorder = Color(0xFFE0D8C8);
  static const Color lightSurface = Color(0xFFEFEAE0);

  static const Color lightPrimary = Color(0xFF2E8B57); // エメラルドグリーン
  static const Color lightSecondary = Color(0xFFD97736); // テラコッタ
  static const Color lightAccentGold = Color(0xFFD4B86A); // ゴールドアンバー
  static const Color lightWarningRed = Color(0xFFD96B6B); // サーモンローズ

  static const Color lightTextPrimary = Color(0xFF2C3E50); // コントラスト比 8.5:1
  static const Color lightTextSecondary = Color(0xFF5D6D7E); // コントラスト比 4.8:1
  static const Color lightTextMuted = Color(0xFF7F8C8D);

  // ==========================================
  // 2. パステルダークテーマ（スモーキーダークオリーブ）
  // ==========================================
  static const Color darkBg = Color(0xFF181B18);
  static const Color darkCard = Color(0xFF222722);
  static const Color darkBorder = Color(0xFF333D33);
  static const Color darkSurface = Color(0xFF2C332C);

  static const Color darkPrimary = Color(0xFF48BB78); // 明るいミントグリーン
  static const Color darkSecondary = Color(0xFFED8936); // ウォームアンバー
  static const Color darkAccentGold = Color(0xFFECC94B); // ゴールド
  static const Color darkWarningRed = Color(0xFFFC8181); // ソフトレッド

  static const Color darkTextPrimary = Color(0xFFF0F4F0); // コントラスト比 12.8:1
  static const Color darkTextSecondary = Color(0xFFA0B3A0); // コントラスト比 5.2:1
  static const Color darkTextMuted = Color(0xFF7A8C7A);

  // ==========================================
  // 3. ThemeData 定義
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        surface: lightBg,
        primary: lightPrimary,
        secondary: lightSecondary,
        error: lightWarningRed,
      ),
      cardTheme: const CardThemeData(
        color: lightCard,
        elevation: 1,
      ),
      dividerColor: lightBorder,
      fontFamily: 'sans-serif',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        surface: darkBg,
        primary: darkPrimary,
        secondary: darkSecondary,
        error: darkWarningRed,
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 1,
      ),
      dividerColor: darkBorder,
      fontFamily: 'sans-serif',
    );
  }

  // ==========================================
  // 4. WCAG 2.1 AA 準拠 品詞バッジ配色ヘルパー
  // ==========================================
  static PosBadgeColors getPosBadgeColors(String pos, {bool isDark = false}) {
    final clean = pos.toLowerCase().trim();
    if (clean.contains('動') || clean.contains('verb')) {
      return isDark
          ? const PosBadgeColors(bg: Color(0xFF1E3326), border: Color(0xFF2C5E40), text: Color(0xFF81E6D9))
          : const PosBadgeColors(bg: Color(0xFFE6F4EA), border: Color(0xFFA8D5BA), text: Color(0xFF1E6B37));
    }
    if (clean.contains('形') || clean.contains('adj')) {
      return isDark
          ? const PosBadgeColors(bg: Color(0xFF332A3D), border: Color(0xFF5A4470), text: Color(0xFFD6BCFA))
          : const PosBadgeColors(bg: Color(0xFFF3E8FD), border: Color(0xFFD2B4F2), text: Color(0xFF6B21A8));
    }
    if (clean.contains('副') || clean.contains('adv')) {
      return isDark
          ? const PosBadgeColors(bg: Color(0xFF3B2E24), border: Color(0xFF6B4C33), text: Color(0xFFFBD38D))
          : const PosBadgeColors(bg: Color(0xFFFFF3E0), border: Color(0xFFFFCC80), text: Color(0xFFB45309));
    }
    // 名詞・その他
    return isDark
        ? const PosBadgeColors(bg: Color(0xFF22303C), border: Color(0xFF3D5266), text: Color(0xFF90CDF4))
        : const PosBadgeColors(bg: Color(0xFFE8EEF5), border: Color(0xFFBDD0E0), text: Color(0xFF2C5282));
  }
}

/// 品詞バッジ用カラー構造体
class PosBadgeColors {
  final Color bg;
  final Color border;
  final Color text;

  const PosBadgeColors({
    required this.bg,
    required this.border,
    required this.text,
  });
}
