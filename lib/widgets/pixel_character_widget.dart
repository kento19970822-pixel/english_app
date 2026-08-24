// コード管理番号: VER-20260824-47
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../db/app_database.dart';

/// キャラクターの成長・進化段階 (F-13)
enum CharacterGrowthState {
  locked, // シルエット（未解放）
  lowHealth, // 元気がない（定着率 1〜49%）
  healthy, // 元気（定着率 50〜79%）
  evolved, // 進化形態（定着率 80%以上 / クリア）
}

/// キャラクターのアクション・行動状態 (F-14)
enum CharacterActionState {
  idle, // 待機（呼吸・瞬き）
  walk, // 歩行（左右トコトコ移動・足振り）
  sleep, // 睡眠（閉じ目・Zzz浮遊）
  humming, // ハミング・喜び（スイングジャンプ・音符ポップアップ）
}

/// キャラクター種族メタデータ
class CharacterSpecies {
  final int id;
  final String name;
  final String japaneseName;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color bellyColor;
  final Color evolvedPrimaryColor;
  final Color evolvedSecondaryColor;

  const CharacterSpecies({
    required this.id,
    required this.name,
    required this.japaneseName,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.bellyColor,
    required this.evolvedPrimaryColor,
    required this.evolvedSecondaryColor,
  });
}

/// 12種類の固有種族マスター
const List<CharacterSpecies> kCharacterSpeciesList = [
  CharacterSpecies(
    id: 0,
    name: 'Chicky',
    japaneseName: 'ヒヨコ',
    description: '元気いっぱいに飛び跳ねる、生まれたての相棒ヒヨコ。',
    primaryColor: Color(0xFFFFD54F),
    secondaryColor: Color(0xFFFFA000),
    bellyColor: Color(0xFFFFF9C4),
    evolvedPrimaryColor: Color(0xFFFFE082),
    evolvedSecondaryColor: Color(0xFFFF6F00),
  ),
  CharacterSpecies(
    id: 1,
    name: 'Kitty',
    japaneseName: 'ネコ',
    description: '好奇心旺盛でちょっぴり気まぐれなドットネコ。',
    primaryColor: Color(0xFFFFAB91),
    secondaryColor: Color(0xFFE64A19),
    bellyColor: Color(0xFFFFF3E0),
    evolvedPrimaryColor: Color(0xFFFF8A80),
    evolvedSecondaryColor: Color(0xFFD50000),
  ),
  CharacterSpecies(
    id: 2,
    name: 'Puppy',
    japaneseName: 'イヌ',
    description: 'いつでもご主人様についてくる忠実で優しい子犬。',
    primaryColor: Color(0xFFD7CCC8),
    secondaryColor: Color(0xFF8D6E63),
    bellyColor: Color(0xFFEFEBE9),
    evolvedPrimaryColor: Color(0xFFFFCC80),
    evolvedSecondaryColor: Color(0xFFE65100),
  ),
  CharacterSpecies(
    id: 3,
    name: 'Bunny',
    japaneseName: 'ウサギ',
    description: '長い耳で英語の微細な発音を聞き分けるウサギ。',
    primaryColor: Color(0xFFF8BBD0),
    secondaryColor: Color(0xFFC2185B),
    bellyColor: Color(0xFFFCE4EC),
    evolvedPrimaryColor: Color(0xFFEA80FC),
    evolvedSecondaryColor: Color(0xFFAA00FF),
  ),
  CharacterSpecies(
    id: 4,
    name: 'Bear',
    japaneseName: 'クマ',
    description: 'のんびり屋だけど勉強熱心な頼もしい子グマ。',
    primaryColor: Color(0xFFBCAAA4),
    secondaryColor: Color(0xFF5D4037),
    bellyColor: Color(0xFFD7CCC8),
    evolvedPrimaryColor: Color(0xFFFFD180),
    evolvedSecondaryColor: Color(0xFFBF360C),
  ),
  CharacterSpecies(
    id: 5,
    name: 'Penguin',
    japaneseName: 'ペンギン',
    description: '涼しい顔で難関英単語をスラスラ覚えるペンギン。',
    primaryColor: Color(0xFF90CAF9),
    secondaryColor: Color(0xFF1976D2),
    bellyColor: Color(0xFFFFFFFF),
    evolvedPrimaryColor: Color(0xFF80D8FF),
    evolvedSecondaryColor: Color(0xFF0091EA),
  ),
  CharacterSpecies(
    id: 6,
    name: 'Frog',
    japaneseName: 'カエル',
    description: 'ピョンピョン跳ねて連続正解ストリークを応援するカエル。',
    primaryColor: Color(0xFFA5D6A7),
    secondaryColor: Color(0xFF388E3C),
    bellyColor: Color(0xFFE8F5E9),
    evolvedPrimaryColor: Color(0xFFB9F6CA),
    evolvedSecondaryColor: Color(0xFF00C853),
  ),
  CharacterSpecies(
    id: 7,
    name: 'Fox',
    japaneseName: 'キツネ',
    description: '知性豊かで華麗なステップを踏む賢いキツネ。',
    primaryColor: Color(0xFFFFCC80),
    secondaryColor: Color(0xFFEF6C00),
    bellyColor: Color(0xFFFFF3E0),
    evolvedPrimaryColor: Color(0xFFFFAB40),
    evolvedSecondaryColor: Color(0xFFFF3D00),
  ),
  CharacterSpecies(
    id: 8,
    name: 'Panda',
    japaneseName: 'パンダ',
    description: 'おっとり癒やし系で学習の疲れを吹き飛ばすパンダ。',
    primaryColor: Color(0xFFCFD8DC),
    secondaryColor: Color(0xFF37474F),
    bellyColor: Color(0xFFECEFF1),
    evolvedPrimaryColor: Color(0xFFB0BEC5),
    evolvedSecondaryColor: Color(0xFF263238),
  ),
  CharacterSpecies(
    id: 9,
    name: 'Dragon',
    japaneseName: 'ドラゴン',
    description: '高い目標に向かって炎の如く情熱を燃やすベビードラゴン。',
    primaryColor: Color(0xFFCE93D8),
    secondaryColor: Color(0xFF7B1FA2),
    bellyColor: Color(0xFFF3E5F5),
    evolvedPrimaryColor: Color(0xFFE040FB),
    evolvedSecondaryColor: Color(0xFF4A148C),
  ),
  CharacterSpecies(
    id: 10,
    name: 'Robo',
    japaneseName: 'ロボ',
    description: '最新AI学習アルゴリズムを搭載した相棒小型ロボット。',
    primaryColor: Color(0xFF80CBC4),
    secondaryColor: Color(0xFF00796B),
    bellyColor: Color(0xFFE0F2F1),
    evolvedPrimaryColor: Color(0xFF64FFDA),
    evolvedSecondaryColor: Color(0xFF00BFA5),
  ),
  CharacterSpecies(
    id: 11,
    name: 'Starlet',
    japaneseName: 'スター',
    description: '暗記の星座から生まれたキラキラ輝く星の精霊。',
    primaryColor: Color(0xFFFFF59D),
    secondaryColor: Color(0xFFFBC02D),
    bellyColor: Color(0xFFFFFDE7),
    evolvedPrimaryColor: Color(0xFFFFFF00),
    evolvedSecondaryColor: Color(0xFFFF8F00),
  ),
];

/// プロシージャルドット絵キャラクターウィジェット
class PixelCharacterWidget extends StatefulWidget {
  final int speciesIndex;
  final CharacterGrowthState growthState;
  final CharacterActionState actionState;
  final Stamp? favoriteStamp;
  final double size;
  final bool isInteractive;
  final VoidCallback? onTap;

  const PixelCharacterWidget({
    super.key,
    required this.speciesIndex,
    this.growthState = CharacterGrowthState.healthy,
    this.actionState = CharacterActionState.idle,
    this.favoriteStamp,
    this.size = 64.0,
    this.isInteractive = false,
    this.onTap,
  });

  /// 暗記率（0〜100%）から成長状態を判定
  static CharacterGrowthState stateFromRate(double rate, bool isUnlocked) {
    if (!isUnlocked) return CharacterGrowthState.locked;
    if (rate >= 80.0) return CharacterGrowthState.evolved;
    if (rate >= 50.0) return CharacterGrowthState.healthy;
    if (rate > 0.0) return CharacterGrowthState.lowHealth;
    return CharacterGrowthState.lowHealth;
  }

  @override
  State<PixelCharacterWidget> createState() => _PixelCharacterWidgetState();
}

class _PixelCharacterWidgetState extends State<PixelCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  CharacterActionState _currentAction = CharacterActionState.idle;

  @override
  void initState() {
    super.initState();
    _currentAction = widget.actionState;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant PixelCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actionState != oldWidget.actionState) {
      _currentAction = widget.actionState;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.growthState == CharacterGrowthState.locked) return;

    if (widget.isInteractive) {
      setState(() {
        _currentAction = CharacterActionState.humming;
      });

      // 2秒後に元の待機/歩行アクションに復帰
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          setState(() {
            _currentAction = widget.actionState;
          });
        }
      });
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final species = kCharacterSpeciesList[widget.speciesIndex % kCharacterSpeciesList.length];

    Widget characterContent = AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PixelCharacterPainter(
            species: species,
            growthState: widget.growthState,
            actionState: _currentAction,
            favoriteStamp: widget.favoriteStamp,
            animValue: _animController.value,
          ),
        );
      },
    );

    if (widget.isInteractive || widget.onTap != null) {
      return GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: characterContent,
      );
    }

    return characterContent;
  }
}

/// プロシージャルキャラクター描画Painter
class _PixelCharacterPainter extends CustomPainter {
  final CharacterSpecies species;
  final CharacterGrowthState growthState;
  final CharacterActionState actionState;
  final Stamp? favoriteStamp;
  final double animValue;

  _PixelCharacterPainter({
    required this.species,
    required this.growthState,
    required this.actionState,
    required this.favoriteStamp,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double pixelSize = size.width / 16.0;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // アニメーション用変数
    final int step = (animValue * 4).floor() % 4; // 0, 1, 2, 3
    final bool isBlinking = animValue > 0.88 && animValue < 0.96;
    final double breathOffsetY = (step % 2 == 1 && actionState != CharacterActionState.sleep) ? -0.6 : 0.0;
    final double walkLegOffset = (actionState == CharacterActionState.walk && (step == 1 || step == 3)) ? 1.0 : 0.0;
    final double humSwingAngle = (actionState == CharacterActionState.humming)
        ? math.sin(animValue * math.pi * 6) * 0.08
        : 0.0;
    final double humJumpOffsetY = (actionState == CharacterActionState.humming)
        ? -math.sin(animValue * math.pi * 4).abs() * 2.0
        : 0.0;

    canvas.save();
    // センタリング & ハミング時のスイング・ジャンプ変換
    canvas.translate(size.width / 2, size.height / 2);
    if (humSwingAngle != 0.0) canvas.rotate(humSwingAngle);
    canvas.translate(-size.width / 2, -size.height / 2 + humJumpOffsetY * pixelSize);

    // 1. カラーパレットの選定
    final Color bodyColor;
    final Color shadeColor;
    final Color bellyColor;
    final Color eyeColor;
    final Color blushColor;
    final Color accessoryColor;

    switch (growthState) {
      case CharacterGrowthState.locked:
        bodyColor = const Color(0xFF4A5568);
        shadeColor = const Color(0xFF2D3748);
        bellyColor = const Color(0xFF718096);
        eyeColor = Colors.transparent;
        blushColor = Colors.transparent;
        accessoryColor = const Color(0xFF2D3748);
        break;
      case CharacterGrowthState.lowHealth:
        // くすみパステルカラー
        bodyColor = Color.lerp(species.primaryColor, const Color(0xFF9E9E9E), 0.45)!;
        shadeColor = Color.lerp(species.secondaryColor, const Color(0xFF616161), 0.45)!;
        bellyColor = Color.lerp(species.bellyColor, const Color(0xFFE0E0E0), 0.3)!;
        eyeColor = const Color(0xFF37474F);
        blushColor = const Color(0xFFB0BEC5);
        accessoryColor = shadeColor;
        break;
      case CharacterGrowthState.healthy:
        bodyColor = species.primaryColor;
        shadeColor = species.secondaryColor;
        bellyColor = species.bellyColor;
        eyeColor = const Color(0xFF212121);
        blushColor = const Color(0xFFFF8A80);
        accessoryColor = species.secondaryColor;
        break;
      case CharacterGrowthState.evolved:
        bodyColor = species.evolvedPrimaryColor;
        shadeColor = species.evolvedSecondaryColor;
        bellyColor = species.bellyColor;
        eyeColor = const Color(0xFF1A237E);
        blushColor = const Color(0xFFFF4081);
        accessoryColor = const Color(0xFFFFD700); // 黄金
        break;
    }

    // 2. 種族別マトリクス描画 (16x16)
    final matrix = _getSpeciesMatrix(species.id, growthState == CharacterGrowthState.evolved);

    for (int r = 0; r < 16; r++) {
      for (int c = 0; c < 16; c++) {
        final char = matrix[r][c];
        if (char == '.') continue;

        double py = (r + breathOffsetY) * pixelSize;
        double px = c * pixelSize;

        // 足の歩行アニメーション
        if (r >= 13 && actionState == CharacterActionState.walk) {
          if (c < 8 && step == 1) py -= walkLegOffset * pixelSize;
          if (c >= 8 && step == 3) py -= walkLegOffset * pixelSize;
        }

        switch (char) {
          case 'B': // メインボディ
            paint.color = bodyColor;
            break;
          case 'S': // シェード・輪郭
            paint.color = shadeColor;
            break;
          case 'W': // お腹・ハイライト
            paint.color = bellyColor;
            break;
          case 'A': // 耳・角・アクセサリ
            paint.color = accessoryColor;
            break;
          case 'M': // 口・くちばし・鼻
            paint.color = (growthState == CharacterGrowthState.locked)
                ? shadeColor
                : const Color(0xFFFF7043);
            break;
          case 'E': // 目
            if (growthState == CharacterGrowthState.locked) {
              paint.color = shadeColor;
            } else if (actionState == CharacterActionState.sleep || isBlinking) {
              // 閉じ目（横線1px）
              paint.color = eyeColor;
            } else {
              paint.color = eyeColor;
            }
            break;
          case 'C': // ほっぺ（チーク）
            paint.color = blushColor;
            break;
          default:
            paint.color = bodyColor;
        }

        // 閉じ目または睡眠時の表現
        if (char == 'E' && (actionState == CharacterActionState.sleep || isBlinking)) {
          canvas.drawRect(
            Rect.fromLTWH(px, py + pixelSize * 0.4, pixelSize, pixelSize * 0.3),
            paint,
          );
        } else {
          canvas.drawRect(
            Rect.fromLTWH(px, py, pixelSize + 0.1, pixelSize + 0.1),
            paint,
          );
        }
      }
    }

    // 3. 進化形態のパーツ（王冠・翼・オーロラ粒子）
    if (growthState == CharacterGrowthState.evolved) {
      _drawEvolutionDecorations(canvas, pixelSize, animValue);
    }

    // 4. アクション状態のエフェクト
    if (growthState != CharacterGrowthState.locked) {
      if (growthState == CharacterGrowthState.lowHealth) {
        // 汗マーク 💧
        _drawSweatDrop(canvas, pixelSize, animValue);
      } else if (actionState == CharacterActionState.sleep) {
        // Zzz 浮遊エフェクト
        _drawZzzEffect(canvas, pixelSize, animValue);
      } else if (actionState == CharacterActionState.humming) {
        // 音符 ♪ ♫ エフェクト
        _drawMusicNotes(canvas, pixelSize, animValue);
      }
    }

    // 5. お気に入りスタンプ胸バッジの合成描画 (F-14)
    if (favoriteStamp != null && growthState != CharacterGrowthState.locked) {
      _drawChestBadge(canvas, pixelSize, favoriteStamp!);
    }

    canvas.restore();
  }

  /// 種族ごとの16x16ドットマトリクス定義
  List<String> _getSpeciesMatrix(int speciesId, bool isEvolved) {
    switch (speciesId % 12) {
      case 0: // ヒヨコ (Chicky)
        return [
          '................',
          '......AAA.......',
          '.....AAAAA......',
          '....BBBBBBB.....',
          '....BEEBEEB.....',
          '...BBMEBMMEB....',
          '...BBCBBBCBB....',
          '..BBBBBBBBBBB...',
          '..BBWWWWWWWBB...',
          '..BBWWWWWWWBB...',
          '..BBBBBBBBBBB...',
          '...BBBBBBBBB....',
          '....BBBBBBB.....',
          '.....SS.SS......',
          '....SSS.SSS.....',
          '................',
        ];
      case 1: // ネコ (Kitty)
        return [
          '..AA.......AA...',
          '..AAAA...AAAA...',
          '...BBBBBBBBB....',
          '..BBBBBBBBBBB...',
          '..BEEBBBBBEEB...',
          '..BEEBMMMBEEB...',
          '..BBCBMMMBCBB...',
          '..BBBBBBBBBBB...',
          '..BBWWWWWWWBB...',
          '..BBWWWWWWWBB.T.',
          '..BBBBBBBBBBB.T.',
          '..BBBBBBBBBBBTT.',
          '...BBBBBBBBB.T..',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 2: // イヌ (Puppy)
        return [
          '..AA.......AA...',
          '.AAAA.....AAAA..',
          '.AABBBBBBBBBAA..',
          '.AABBBBBBBBBAA..',
          '..BEEBBBBBEEB...',
          '..BEEBMMMBEEB...',
          '..BBCBMMMBCBB...',
          '..BBBBBBBBBBB...',
          '..BBWWWWWWWBB...',
          '..BBWWWWWWWBB.T.',
          '..BBBBBBBBBBBTT.',
          '..BBBBBBBBBBB...',
          '...BBBBBBBBB....',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 3: // ウサギ (Bunny)
        return [
          '..AA.......AA...',
          '..AA.......AA...',
          '..AAAA...AAAA...',
          '..AABBBBBBBAA...',
          '..BBBBBBBBBBB...',
          '..BEEBBBBBEEB...',
          '..BEEBMMMBEEB...',
          '..BBCBMMMBCBB...',
          '..BBBBBBBBBBB...',
          '..BBWWWWWWWBB...',
          '..BBWWWWWWWBB.T.',
          '..BBBBBBBBBBBTT.',
          '...BBBBBBBBB....',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 4: // クマ (Bear)
        return [
          '.AAA.......AAA..',
          '.AAAA.....AAAA..',
          '..BBBBBBBBBBB...',
          '..BBBBBBBBBBB...',
          '..BEEBBBBBEEB...',
          '..BEEBMMMBEEB...',
          '..BBCBMMMBCBB...',
          '..BBBBBBBBBBB...',
          '..BBWWWWWWWBB...',
          '..BBWWWWWWWBB...',
          '..BBBBBBBBBBB...',
          '..BBBBBBBBBBB...',
          '...BBBBBBBBB....',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 5: // ペンギン (Penguin)
        return [
          '................',
          '.....SSSSS......',
          '....SSSSSSS.....',
          '...SSEESSSEESS..',
          '...SSEEEMEEESS..',
          '...SSSSSMMSSSS..',
          '..SSSSSCSSCССSS.',
          '..SSSWWWWWWWSS..',
          '..SSSWWWWWWWSS..',
          '..SSSWWWWWWWSS..',
          '..SSSWWWWWWWSS..',
          '...SSSWWWWWSS...',
          '....SSSSSSSSS...',
          '.....MM...MM....',
          '....MMM...MMM...',
          '................',
        ];
      case 6: // カエル (Frog)
        return [
          '..AAA.....AAA...',
          '.AAAAA...AAAAA..',
          '.AAEEA...AAEEA..',
          '.AABBBBBBBBBAA..',
          '..BBBBBBBBBBB...',
          '..BBBBMMMBBBB...',
          '..BBCBMMMBCBB...',
          '..BBBBBBBBBBB...',
          '..BBWWWWWWWBB...',
          '..BBWWWWWWWBB...',
          '..BBBBBBBBBBB...',
          '..BBBBBBBBBBB...',
          '...BBBBBBBBB....',
          '..SSSS...SSSS...',
          '..SSSS...SSSS...',
          '................',
        ];
      case 7: // キツネ (Fox)
        return [
          '.AA.........AA..',
          '.AAAA.....AAAA..',
          '..AABBBBBBBAA...',
          '..BBBBBBBBBBB...',
          '..BEEBBBBBEEB...',
          '..BEEBMMMBEEB.TT',
          '..BBCBMMMBCBBTTT',
          '..BBBBBBBBBB.TTT',
          '..BBWWWWWWWB.TT.',
          '..BBWWWWWWWB..T.',
          '..BBBBBBBBBB....',
          '..BBBBBBBBBBB...',
          '...BBBBBBBBB....',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 8: // パンダ (Panda)
        return [
          '.AAA.......AAA..',
          '.AAAA.....AAAA..',
          '..BBBBBBBBBBB...',
          '..BSSBBBBBSSB...',
          '..BSEBBBBBSEB...',
          '..BSSBMMMBSSB...',
          '..BBCBMMMBCBB...',
          '..SSSSSSSSSSS...',
          '..SSWWWWWWWSS...',
          '..SSWWWWWWWSS...',
          '..BBBBBBBBBBB...',
          '..BBBBBBBBBBB...',
          '...BBBBBBBBB....',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 9: // ドラゴン (Dragon)
        return [
          '.AA.........AA..',
          '.AAAA.AAA.AAAA..',
          '..AABBBBBBBAA...',
          '..BBBBBBBBBBB...',
          '..BEEBBBBBEEB.TT',
          '..BEEBMMMBEEBTTT',
          '..BBCBMMMBCBBTT.',
          'T.BBBBBBBBBBB.T.',
          'TTBBWWWWWWWB....',
          '.TBBWWWWWWWB....',
          '..BBBBBBBBBBB...',
          '..BBBBBBBBBBB...',
          '...BBBBBBBBB....',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 10: // ロボ (Robo)
        return [
          '.......AAA......',
          '.......AAA......',
          '..SSSSSSSSSSS...',
          '..SBBBBBBBBBS...',
          '..SBEEBBBEEBS...',
          '..SBEEBBBEEBS...',
          '..SBBBMMMBBBS...',
          '..SSSSSSSSSSS...',
          '..SBBWWWWWWBSS..',
          '..SBBWWWWWWBSS..',
          '..SBBBBBBBBBS...',
          '..SSSSSSSSSSS...',
          '...SSSSSSSSS....',
          '....SS...SS.....',
          '....SS...SS.....',
          '................',
        ];
      case 11: // スター (Starlet)
      default:
        return [
          '.......AAA......',
          '......AAAAA.....',
          '..AA.AAAAAAA.AA.',
          '...AAAAAAAAAAA..',
          '..AAABEEBEEBAAA.',
          '...AABMEBMMEBA..',
          '....ABCBMMMCBA..',
          '...AAAAAAAAAAA..',
          '..AAAAWWWWWAAAA.',
          '..AA.AWWWWW.AA..',
          '.....AAAAAAA....',
          '....AAAAAAAAA...',
          '...AAA.....AAA..',
          '..AAA.......AAA.',
          '..AA.........AA.',
          '................',
        ];
    }
  }

  /// 進化形態のパーツ（王冠・翼・オーラ星粒子）
  void _drawEvolutionDecorations(Canvas canvas, double pixelSize, double anim) {
    final goldPaint = Paint()..color = const Color(0xFFFFD700);
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    final wingPaint = Paint()..color = const Color(0xFFE1F5FE).withAlpha(220);
    final starPaint = Paint()..color = const Color(0xFFFFF9C4);

    // 1. 王冠 (頭上: row 0-2, col 5-10)
    canvas.drawRect(Rect.fromLTWH(5 * pixelSize, 0 * pixelSize, pixelSize, pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(7.5 * pixelSize, 0 * pixelSize, pixelSize, pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(10 * pixelSize, 0 * pixelSize, pixelSize, pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(5 * pixelSize, 1 * pixelSize, 6 * pixelSize, pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(7.5 * pixelSize, 1 * pixelSize, pixelSize, pixelSize), rubyPaint);

    // 2. 天使の翼 (左右)
    final wingOffset = math.sin(anim * math.pi * 2) * 0.6;
    // 左翼
    canvas.drawRect(Rect.fromLTWH(0 * pixelSize, (5 + wingOffset) * pixelSize, 2 * pixelSize, 3 * pixelSize), wingPaint);
    // 右翼
    canvas.drawRect(Rect.fromLTWH(14 * pixelSize, (5 + wingOffset) * pixelSize, 2 * pixelSize, 3 * pixelSize), wingPaint);

    // 3. キラキラ星粒子 (周囲に浮遊)
    final p1Y = (3 + math.sin(anim * math.pi * 2) * 2) * pixelSize;
    final p2Y = (11 + math.cos(anim * math.pi * 2) * 2) * pixelSize;
    canvas.drawCircle(Offset(2 * pixelSize, p1Y), pixelSize * 0.5, starPaint);
    canvas.drawCircle(Offset(14 * pixelSize, p2Y), pixelSize * 0.5, starPaint);
  }

  /// 汗マーク 💧
  void _drawSweatDrop(Canvas canvas, double pixelSize, double anim) {
    final sweatPaint = Paint()..color = const Color(0xFF42A5F5);
    final dropY = (4 + (anim * 2) % 2.5) * pixelSize;
    canvas.drawRect(Rect.fromLTWH(13 * pixelSize, dropY, 1.2 * pixelSize, 1.8 * pixelSize), sweatPaint);
  }

  /// Zzz 浮遊エフェクト
  void _drawZzzEffect(Canvas canvas, double pixelSize, double anim) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final progress = anim; // 0.0 to 1.0
    final alpha = (math.sin(progress * math.pi) * 255).clamp(0, 255).toInt();

    final zOffset = Offset(
      (11 + progress * 2) * pixelSize,
      (4 - progress * 4) * pixelSize,
    );

    textPainter.text = TextSpan(
      text: 'z',
      style: TextStyle(
        fontSize: pixelSize * 3,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF7E57C2).withAlpha(alpha),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, zOffset);
  }

  /// 音符 ♪ ♫ エフェクト
  void _drawMusicNotes(Canvas canvas, double pixelSize, double anim) {
    final notePaint = Paint()..color = const Color(0xFFFF4081);
    final noteY = (2 - math.sin(anim * math.pi * 2).abs() * 3) * pixelSize;
    final noteX1 = (3 + math.sin(anim * math.pi * 4) * 1.5) * pixelSize;
    final noteX2 = (12 - math.sin(anim * math.pi * 4) * 1.5) * pixelSize;

    // 音符1 ♪
    canvas.drawCircle(Offset(noteX1, noteY), pixelSize * 0.8, notePaint);
    canvas.drawRect(Rect.fromLTWH(noteX1 + pixelSize * 0.4, noteY - pixelSize * 2, pixelSize * 0.4, pixelSize * 2), notePaint);

    // 音符2 ♫
    canvas.drawCircle(Offset(noteX2, noteY + pixelSize), pixelSize * 0.7, notePaint);
    canvas.drawRect(Rect.fromLTWH(noteX2 + pixelSize * 0.3, noteY - pixelSize, pixelSize * 0.3, pixelSize * 1.8), notePaint);
  }

  /// お気に入りスタンプ胸バッジ合成描画 (F-14)
  void _drawChestBadge(Canvas canvas, double pixelSize, Stamp stamp) {
    final badgeCenter = Offset(8 * pixelSize, 9.5 * pixelSize);
    final double badgeRadius = pixelSize * 1.6;

    // 1. ゴールドバッジ外枠
    final goldPaint = Paint()..color = const Color(0xFFFFD700);
    final borderPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(badgeCenter, badgeRadius, goldPaint);
    canvas.drawCircle(badgeCenter, badgeRadius, borderPaint);

    // 2. スタンプのミニチュアモチーフ（星 / クラウン / ハート等のドット）
    final motifPaint = Paint()..color = const Color(0xFFD32F2F);
    final double miniPx = pixelSize * 0.4;

    // 3x3 のミニチュアシンボル
    final miniMatrix = [
      [0, 1, 0],
      [1, 1, 1],
      [0, 1, 0],
    ];

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (miniMatrix[r][c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              badgeCenter.dx - 1.5 * miniPx + c * miniPx,
              badgeCenter.dy - 1.5 * miniPx + r * miniPx,
              miniPx,
              miniPx,
            ),
            motifPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelCharacterPainter oldDelegate) {
    return oldDelegate.species.id != species.id ||
        oldDelegate.growthState != growthState ||
        oldDelegate.actionState != actionState ||
        oldDelegate.favoriteStamp?.id != favoriteStamp?.id ||
        oldDelegate.animValue != animValue;
  }
}
