// コード管理番号: VER-20260825-12
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../db/app_database.dart';

/// 全チャプター数（31,130単語 ÷ 100単語/章）
const int kTotalChapterCount = 312;

/// キャラクターの成長・進化段階 (F-13)
enum CharacterGrowthState {
  locked, // ① シルエット（未解放 または 暗記率0%: 完全に均一な黒ベタ塗り）
  lowHealth, // ② 元気がない（暗記率 1〜49%: 基本形・くすみ色・下向き目・汗💧）
  healthy, // ③ 元気（暗記率 50〜79%: 鮮やか色・パッチリ目・笑顔・呼吸バウンド）
  evolved, // ④ 進化形態（暗記率 80%以上 / 章マスター: 元特徴維持・王冠・翼・オーラ星粒子✨）
}

/// キャラクターのアクション・行動状態 (F-14)
enum CharacterActionState {
  idle, // 待機（呼吸・瞬き）
  walk, // 歩行（左右トコトコ移動・足振り）
  sleep, // 睡眠（閉じ目・Zzz浮遊）
  humming, // ハミング・喜び（スイングジャンプ・音符ポップアップ）
}

/// キャラクターの8大系統
enum CharacterCategory {
  animal('動物系', '🐾'),
  bird('鳥・飛行系', '🕊️'),
  aquatic('水棲系', '🐟'),
  plant('植物・自然系', '🌿'),
  monster('モンスター系', '👾'),
  fantasy('ファンタジー系', '🐲'),
  humanoid('人型・妖精系', '🧚'),
  special('特殊・コズミック系', '🤖');

  final String label;
  final String icon;
  const CharacterCategory(this.label, this.icon);

  static CharacterCategory fromChapter(int chapter) {
    final idx = (chapter - 1).clamp(0, kTotalChapterCount - 1);
    return _kChapterCategories[idx];
  }
}

/// 312チャプターの系統均等・ごちゃまぜ決定論的マッピング (固定シードで完全一意)
final List<CharacterCategory> _kChapterCategories = () {
  final List<CharacterCategory> pool = [
    ...List.filled(60, CharacterCategory.animal),
    ...List.filled(35, CharacterCategory.bird),
    ...List.filled(35, CharacterCategory.aquatic),
    ...List.filled(35, CharacterCategory.plant),
    ...List.filled(60, CharacterCategory.monster),
    ...List.filled(40, CharacterCategory.fantasy),
    ...List.filled(30, CharacterCategory.humanoid),
    ...List.filled(17, CharacterCategory.special),
  ];
  final rng = math.Random(20260825);
  for (int i = pool.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final temp = pool[i];
    pool[i] = pool[j];
    pool[j] = temp;
  }
  return pool;
}();

/// 系統内でのインデックスオフセット
final List<int> _kChapterCategoryOffsets = () {
  final Map<CharacterCategory, int> counts = {};
  final List<int> offsets = [];
  for (final cat in _kChapterCategories) {
    final current = counts[cat] ?? 0;
    offsets.add(current);
    counts[cat] = current + 1;
  }
  return offsets;
}();

/// キャラクター種族メタデータ (48x48 高精細ドットモデル)
class CharacterSpecies {
  final int chapter; // 対応チャプター番号 (1..374)
  final int id; // 0..373
  final String name;
  final String japaneseName;
  final CharacterCategory category;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color bellyColor;
  final Color outlineColor;
  final Color accessoryColor;
  final Color evolvedPrimaryColor;
  final Color evolvedSecondaryColor;
  final String coreFeature;

  const CharacterSpecies({
    required this.chapter,
    required this.id,
    required this.name,
    required this.japaneseName,
    required this.category,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.bellyColor,
    this.outlineColor = const Color(0xFF2C302E),
    required this.accessoryColor,
    required this.evolvedPrimaryColor,
    required this.evolvedSecondaryColor,
    required this.coreFeature,
  });
}

/// 系統ごとの固有ベースモチーフ辞書
const List<Map<String, dynamic>> _kAnimalMotifs = [
  {'ja': 'ミケネコ', 'en': 'Calico', 'feat': '三角のネコ耳・三毛模様・丸いしっぽ', 'p': 0xFFFFB74D, 's': 0xFFE65100, 'b': 0xFFFFF3E0, 'a': 0xFF8D6E63},
  {'ja': 'しばいぬ', 'en': 'Shiba', 'feat': 'ピンと立った耳・赤バンダナ・巻尾', 'p': 0xFFFFB300, 's': 0xFFB71C1C, 'b': 0xFFFFF8E1, 'a': 0xFF6D4C41},
  {'ja': 'ロップウサギ', 'en': 'LopBunny', 'feat': '長い垂れ耳・ふわふわ胸毛・丸い鼻', 'p': 0xFFF48FB1, 's': 0xFFC2185B, 'b': 0xFFFCE4EC, 'a': 0xFFF06292},
  {'ja': 'こぐま', 'en': 'BearCub', 'feat': '丸いクマ耳・大きな胸あて・温かい茶毛', 'p': 0xFF8D6E63, 's': 0xFF4E342E, 'b': 0xFFD7CCC8, 'a': 0xFFA1887F},
  {'ja': 'こぎつね', 'en': 'FoxCub', 'feat': '大きな尖り耳・白い頬毛・ふさふさの尾', 'p': 0xFFFF9800, 's': 0xFFE65100, 'b': 0xFFFFFDE7, 'a': 0xFF3E2723},
  {'ja': 'パンダ', 'en': 'Panda', 'feat': '黒いタレ目・黒耳・手に持った笹', 'p': 0xFFFAFAFA, 's': 0xFF212121, 'b': 0xFFFFFFFF, 'a': 0xFF81C784},
  {'ja': 'シマリス', 'en': 'Squirrel', 'feat': '背中のしま模様・ドングリ帽子・大尾', 'p': 0xFFA1887F, 's': 0xFF5D4037, 'b': 0xFFEFEBE9, 'a': 0xFFFFB300},
  {'ja': 'コアラ', 'en': 'Koala', 'feat': '大きなフサフサ耳・大きな黒鼻・灰毛', 'p': 0xFFB0BEC5, 's': 0xFF546E7A, 'b': 0xFFECEFF1, 'a': 0xFF37474F},
  {'ja': 'ハリネズミ', 'en': 'Hedgehog', 'feat': '背中のやわらかトゲ・丸いお腹・黒つぶ目', 'p': 0xFFD7CCC8, 's': 0xFF8D6E63, 'b': 0xFFF5F5F5, 'a': 0xFF4E342E},
  {'ja': 'レッサーパンダ', 'en': 'RedPanda', 'feat': '赤茶の毛並み・白い眉毛・しましま尾', 'p': 0xFFFF7043, 's': 0xFFBF360C, 'b': 0xFFFFF3E0, 'a': 0xFF3E2723},
  {'ja': 'オオカミの子', 'en': 'WolfPup', 'feat': '銀灰色の毛並み・凛々しい瞳・青マフラー', 'p': 0xFF90A4AE, 's': 0xFF37474F, 'b': 0xFFECEFF1, 'a': 0xFF42A5F5},
  {'ja': 'アルパカ', 'en': 'Alpaca', 'feat': 'もこもこの首毛・長い首・やさしい瞳', 'p': 0xFFFFF8E1, 's': 0xFFFFE082, 'b': 0xFFFFFFFF, 'a': 0xFFFF8A80},
];

const List<Map<String, dynamic>> _kBirdMotifs = [
  {'ja': 'ヒヨコ', 'en': 'Chicky', 'feat': '黄色いまん丸ボディ・小羽・オレンジくちばし', 'p': 0xFFFFEB3B, 's': 0xFFFF9800, 'b': 0xFFFFFDE7, 'a': 0xFFFF5722},
  {'ja': 'ペンギン', 'en': 'Penguin', 'feat': '白いお腹・パタパタフリッパー・黄くちばし', 'p': 0xFF37474F, 's': 0xFF263238, 'b': 0xFFFFFFFF, 'a': 0xFFFF9800},
  {'ja': 'フクロウ', 'en': 'Owl', 'feat': '丸眼鏡のような大きな目・羽角・茶の羽模様', 'p': 0xFFA1887F, 's': 0xFF4E342E, 'b': 0xFFEFEBE9, 'a': 0xFFFFB300},
  {'ja': 'オウム', 'en': 'Parrot', 'feat': 'トロピカルなトサカ・鮮やかな羽・丸いくちばし', 'p': 0xFF26A69A, 's': 0xFF00695C, 'b': 0xFFFFF9C4, 'a': 0xFFFF1744},
  {'ja': 'スズメ', 'en': 'Sparrow', 'feat': '茶色い頭巾・黒いほっぺ斑点・ちょこんとした足', 'p': 0xFF8D6E63, 's': 0xFF4E342E, 'b': 0xFFFFF8E1, 'a': 0xFF212121},
  {'ja': 'フラミンゴ', 'en': 'Flamingo', 'feat': '鮮やかなピンク羽・一本足立ち・曲がりくちばし', 'p': 0xFFFF80AB, 's': 0xFFF50057, 'b': 0xFFFCE4EC, 'a': 0xFF212121},
  {'ja': 'アヒル', 'en': 'Ducky', 'feat': '真っ白な羽毛・平たい黄色いくちばし・丸い尻尾', 'p': 0xFFFFFFFF, 's': 0xFFCFD8DC, 'b': 0xFFFAFAFA, 'a': 0xFFFFB300},
  {'ja': 'ハト', 'en': 'Dove', 'feat': '首元のオパール光沢・くわえたオリーブ葉・銀灰羽', 'p': 0xFFB0BEC5, 's': 0xFF78909C, 'b': 0xFFECEFF1, 'a': 0xFF66BB6A},
];

const List<Map<String, dynamic>> _kAquaticMotifs = [
  {'ja': 'あまがえる', 'en': 'Froggy', 'feat': '頭上の大きな丸目・エメラルドグリーン・白い喉', 'p': 0xFF81C784, 's': 0xFF388E3C, 'b': 0xFFE8F5E9, 'a': 0xFF2E7D32},
  {'ja': 'クラゲぼうや', 'en': 'Jelly', 'feat': '丸い傘・ゆらゆら触手・透き通るブルー', 'p': 0xFF80DEEA, 's': 0xFF00ACC1, 'b': 0xFFE0F7FA, 'a': 0xFF4DD0E1},
  {'ja': 'タコまる', 'en': 'Octy', 'feat': 'おちょぼ口・くるくる足・赤い丸頭', 'p': 0xFFEF5350, 's': 0xFFC62828, 'b': 0xFFFFEBEE, 'a': 0xFFFFCDD2},
  {'ja': 'イルカくん', 'en': 'Dolphin', 'feat': 'なめらかな流線形・元気な背びれ・笑顔の口元', 'p': 0xFF42A5F5, 's': 0xFF1976D2, 'b': 0xFFE3F2FD, 'a': 0xFF90CAF9},
  {'ja': 'ウミガメ', 'en': 'Turtle', 'feat': '六角形の甲羅・大きなヒレ足・のんびりした目', 'p': 0xFF66BB6A, 's': 0xFF2E7D32, 'b': 0xFFC8E6C9, 'a': 0xFF8D6E63},
  {'ja': 'クリオネ', 'en': 'Clione', 'feat': '氷の妖精の羽・透明な赤い心臓・クリスタルボディ', 'p': 0xFFE0F7FA, 's': 0xFF80DEEA, 'b': 0xFFFFFFFF, 'a': 0xFFFF5252},
  {'ja': 'マンタ', 'en': 'Manta', 'feat': '広いひれ翼・白い腹・長い尾針', 'p': 0xFF546E7A, 's': 0xFF263238, 'b': 0xFFFFFFFF, 'a': 0xFF78909C},
  {'ja': 'キンギョ', 'en': 'Goldfish', 'feat': 'ひらひらした尾びれ・ぷっくりほっぺ・朱色の鱗', 'p': 0xFFFF7043, 's': 0xFFD84315, 'b': 0xFFFFF3E0, 'a': 0xFFFFAB91},
];

const List<Map<String, dynamic>> _kPlantMotifs = [
  {'ja': 'プチトマト', 'en': 'Tomaty', 'feat': '頭の緑のヘタ・真っ赤な丸い体・つやつやハイライト', 'p': 0xFFE53935, 's': 0xFFB71C1C, 'b': 0xFFFFCDD2, 'a': 0xFF43A047},
  {'ja': 'サボテンくん', 'en': 'Cactus', 'feat': '両腕の枝・頭のピンクの花・トゲトゲ模様', 'p': 0xFF66BB6A, 's': 0xFF2E7D32, 'b': 0xFFC8E6C9, 'a': 0xFFFF4081},
  {'ja': 'キノコちゃん', 'en': 'Shroom', 'feat': '大きな傘・白い水玉模様・白い軸ボディ', 'p': 0xFFAB47BC, 's': 0xFF6A1B9A, 'b': 0xFFF3E5F5, 'a': 0xFFFFFFFF},
  {'ja': 'ヒマワリぼうや', 'en': 'Sunflower', 'feat': '黄金の花びら王冠・茶色い丸顔・緑の葉手', 'p': 0xFFFFCA28, 's': 0xFFF57F17, 'b': 0xFFFFF8E1, 'a': 0xFF795548},
  {'ja': 'ドングリぼうや', 'en': 'Acorn', 'feat': 'しましまの帽子・ツヤツヤの茶色ボディ・ちょこん足', 'p': 0xFF8D6E63, 's': 0xFF4E342E, 'b': 0xFFD7CCC8, 'a': 0xFF6D4C41},
  {'ja': 'リンゴちゃん', 'en': 'Apple', 'feat': '一本の若葉の茎・丸い赤リンゴ体・愛らしい瞳', 'p': 0xFFF44336, 's': 0xFFC62828, 'b': 0xFFFFEBEE, 'a': 0xFF81C784},
  {'ja': 'クローバー', 'en': 'Clover', 'feat': '四つ葉のヘッドドレス・若草色のケープ・幸運のオーラ', 'p': 0xFF4CAF50, 's': 0xFF1B5E20, 'b': 0xFFE8F5E9, 'a': 0xFF81C784},
  {'ja': 'ダイコンくん', 'en': 'Radish', 'feat': '頭のふさふさ青首葉・真っ白なボディ・赤いほっぺ', 'p': 0xFFFAFAFA, 's': 0xFFCFD8DC, 'b': 0xFFFFFFFF, 'a': 0xFF43A047},
];

const List<Map<String, dynamic>> _kMonsterMotifs = [
  {'ja': 'ぷるぷるスライム', 'en': 'Slimey', 'feat': '水滴型の頭とんがり・ぷるぷるボディ・大きな瞳', 'p': 0xFF42A5F5, 's': 0xFF1565C0, 'b': 0xFFE3F2FD, 'a': 0xFF90CAF9},
  {'ja': 'おばけちゃん', 'en': 'Ghosty', 'feat': 'ひらひらした裾・まん丸黒目・浮遊ポーズ', 'p': 0xFFEDE7F6, 's': 0xFF7E57C2, 'b': 0xFFFFFFFF, 'a': 0xFFB39DDB},
  {'ja': 'コバコモドキ', 'en': 'Mimic', 'feat': '宝箱のフタ頭・赤い舌・金色の金具', 'p': 0xFF8D6E63, 's': 0xFF4E342E, 'b': 0xFFFFD54F, 'a': 0xFFFF1744},
  {'ja': 'プチゴーレム', 'en': 'Golem', 'feat': '四角い石ブロックボディ・光る瞳・苔のアクセント', 'p': 0xFF78909C, 's': 0xFF37474F, 'b': 0xFFB0BEC5, 'a': 0xFF81C784},
  {'ja': 'マンドラゴラ', 'en': 'Mandrake', 'feat': '土色の根っこ体・頭の芽吹き葉・驚いた丸口', 'p': 0xFFA1887F, 's': 0xFF5D4037, 'b': 0xFFD7CCC8, 'a': 0xFF66BB6A},
  {'ja': 'こうもりモドキ', 'en': 'Batty', 'feat': '小さな紫のコウモリ翼・牙・丸い耳', 'p': 0xFF7E57C2, 's': 0xFF4527A0, 'b': 0xFFEDE7F6, 'a': 0xFFFFB300},
  {'ja': 'カボチャランタン', 'en': 'Pumpkin', 'feat': 'オレンジの彫り顔・緑のヘタ・キャンドルの光', 'p': 0xFFFF9800, 's': 0xFFE65100, 'b': 0xFFFFF3E0, 'a': 0xFF43A047},
  {'ja': 'シャドウパップ', 'en': 'ShadowPup', 'feat': '漆黒の毛並み・光る金色の瞳・煙のしっぽ', 'p': 0xFF37474F, 's': 0xFF212121, 'b': 0xFF455A64, 'a': 0xFFFFD700},
];

const List<Map<String, dynamic>> _kFantasyMotifs = [
  {'ja': 'プチドラゴン', 'en': 'Drake', 'feat': '小さなドラゴンのツノ・背中の羽・ギザギザ尾', 'p': 0xFFEF5350, 's': 0xFFC62828, 'b': 0xFFFFE082, 'a': 0xFFFF9800},
  {'ja': 'ユニコーン', 'en': 'Unicorn', 'feat': '額の黄金の一本角・レインボーたてがみ・優雅な瞳', 'p': 0xFFF3E5F5, 's': 0xFFBA68C8, 'b': 0xFFFFFFFF, 'a': 0xFFFFD700},
  {'ja': 'ペガサス', 'en': 'Pegasus', 'feat': '純白の大きな翼・青い瞳・銀の蹄', 'p': 0xFFE1F5FE, 's': 0xFF81D4FA, 'b': 0xFFFFFFFF, 'a': 0xFF0288D1},
  {'ja': 'フェニックス', 'en': 'Phoenix', 'feat': '燃える紅蓮の羽・黄金の冠毛・炎の尾', 'p': 0xFFFF5722, 's': 0xFFBF360C, 'b': 0xFFFFE082, 'a': 0xFFFFD700},
  {'ja': 'グリフォン', 'en': 'Griffin', 'feat': '猛禽の頭と翼・ライオンの胴体・鋭い瞳', 'p': 0xFFFFB300, 's': 0xFFE65100, 'b': 0xFFFFF8E1, 'a': 0xFF8D6E63},
  {'ja': 'キマイラちゃん', 'en': 'Chimera', 'feat': 'ライオン耳・ヤギの小角・ヘビのしっぽ', 'p': 0xFFFF8A65, 's': 0xFFD84315, 'b': 0xFFFFCCBC, 'a': 0xFF66BB6A},
  {'ja': 'クリスタル竜', 'en': 'CrystalDrake', 'feat': '透き通るサファイアの鱗・氷の角・星の羽', 'p': 0xFF4FC3F7, 's': 0xFF0288D1, 'b': 0xFFE1F5FE, 'a': 0xFFB3E5FC},
  {'ja': '九尾のキツネ', 'en': 'NineTails', 'feat': '9本の扇状の尾・額の朱印・神聖な白い毛', 'p': 0xFFFFFDE7, 's': 0xFFFFD54F, 'b': 0xFFFFFFFF, 'a': 0xFFFF1744},
];

const List<Map<String, dynamic>> _kHumanoidMotifs = [
  {'ja': 'もりの妖精', 'en': 'Pixie', 'feat': '尖ったエルフ耳・花の帽子・背中の薄羽', 'p': 0xFFFFE082, 's': 0xFF81C784, 'b': 0xFFFFF9C4, 'a': 0xFF80DEEA},
  {'ja': 'ちび勇者', 'en': 'Hero', 'feat': '青い勇者のマント・革ベルト・木製ミニソード', 'p': 0xFF42A5F5, 's': 0xFF1565C0, 'b': 0xFFFFE082, 'a': 0xFF8D6E63},
  {'ja': 'ちび魔女', 'en': 'Witch', 'feat': 'とんがり魔女帽子・紫のマント・星のステッキ', 'p': 0xFF7E57C2, 's': 0xFF4527A0, 'b': 0xFFEDE7F6, 'a': 0xFFFFCA28},
  {'ja': 'エンジェル', 'en': 'Angel', 'feat': '頭上の光の天使輪・小さな純白翼・白いドレス', 'p': 0xFFFFF9C4, 's': 0xFFFFD54F, 'b': 0xFFFFFFFF, 'a': 0xFFFFEE58},
  {'ja': 'プチデビル', 'en': 'Devil', 'feat': '小さなコウモリ角・赤いマント・三叉の槍尾', 'p': 0xFFE91E63, 's': 0xFF880E4F, 'b': 0xFFFCE4EC, 'a': 0xFF212121},
  {'ja': 'マーメイド', 'en': 'Mermaid', 'feat': 'エメラルドの魚尾・真珠の髪飾り・波色の髪', 'p': 0xFF26A69A, 's': 0xFF00695C, 'b': 0xFFE0F2F1, 'a': 0xFFFF80AB},
  {'ja': 'ノームじい', 'en': 'Gnome', 'feat': '赤い三角帽子・白いふさふさ髭・青い作業着', 'p': 0xFFEF5350, 's': 0xFFC62828, 'b': 0xFFFFFFFF, 'a': 0xFF1E88E5},
  {'ja': 'ちびナイト', 'en': 'Knight', 'feat': 'シルバーの兜・羽飾り・小さな丸盾', 'p': 0xFF90A4AE, 's': 0xFF455A64, 'b': 0xFFECEFF1, 'a': 0xFFFF1744},
];

const List<Map<String, dynamic>> _kSpecialMotifs = [
  {'ja': 'レトロロボ', 'en': 'Robo', 'feat': '頭のアンテナ・四角い頭部・胸のメーター画面', 'p': 0xFF78909C, 's': 0xFF37474F, 'b': 0xFF80CBC4, 'a': 0xFFFFCA28},
  {'ja': 'ほしの子', 'en': 'Starlet', 'feat': '五角の星型ヘッド・キラキラの瞳・星のしっぽ', 'p': 0xFFFFEE58, 's': 0xFFF57F17, 'b': 0xFFFFFDE7, 'a': 0xFFFF4081},
  {'ja': 'プチUFO', 'en': 'Ufo', 'feat': 'ドーム型ガラス頭・点滅シグナルランプ・ビーム足', 'p': 0xFF26C6DA, 's': 0xFF00838F, 'b': 0xFFE0F7FA, 'a': 0xFFFFEE58},
  {'ja': '歯車ボーイ', 'en': 'Clockwork', 'feat': '頭上のぜんまいキー・真鍮の歯車ボディ・ゴーグル', 'p': 0xFFFFB300, 's': 0xFFE65100, 'b': 0xFFFFF8E1, 'a': 0xFF795548},
  {'ja': 'クリスタルくん', 'en': 'Crystal', 'feat': '多面体の宝石頭・光の屈折プリズム・浮遊クリスタル', 'p': 0xFFAB47BC, 's': 0xFF6A1B9A, 'b': 0xFFF3E5F5, 'a': 0xFF80DEEA},
  {'ja': 'ムーンライト', 'en': 'Moon', 'feat': '三日月型の頭部・夜空色のローブ・星屑の粉', 'p': 0xFFFFF59D, 's': 0xFFFBC02D, 'b': 0xFFFFF9C4, 'a': 0xFF5C6BC0},
];

/// 指定チャプター（1..374）に対応する固有キャラクター種族を生成・取得
CharacterSpecies getCharacterSpecies(int chapter) {
  final clampedChap = chapter.clamp(1, kTotalChapterCount);
  final id = clampedChap - 1;
  final category = _kChapterCategories[id];
  final offsetInCat = _kChapterCategoryOffsets[id];

  List<Map<String, dynamic>> motifList;
  switch (category) {
    case CharacterCategory.animal:
      motifList = _kAnimalMotifs;
      break;
    case CharacterCategory.bird:
      motifList = _kBirdMotifs;
      break;
    case CharacterCategory.aquatic:
      motifList = _kAquaticMotifs;
      break;
    case CharacterCategory.plant:
      motifList = _kPlantMotifs;
      break;
    case CharacterCategory.monster:
      motifList = _kMonsterMotifs;
      break;
    case CharacterCategory.fantasy:
      motifList = _kFantasyMotifs;
      break;
    case CharacterCategory.humanoid:
      motifList = _kHumanoidMotifs;
      break;
    case CharacterCategory.special:
      motifList = _kSpecialMotifs;
      break;
  }

  final base = motifList[offsetInCat % motifList.length];
  final cycle = offsetInCat ~/ motifList.length;

  // サイクルごとに固有の称号・バリエーション名とカラー微調整を生成
  final prefixes = ['', '若き', '勇気の', '月光の', '黄金の', '大樹の', '星の', '古代の', '虹の', '真紅の'];
  final prefix = cycle > 0 && cycle < prefixes.length ? prefixes[cycle] : '';
  final japaneseName = prefix.isNotEmpty ? '$prefix${base['ja']}' : base['ja'] as String;
  final name = cycle > 0 ? '${base['en']} $cycle' : base['en'] as String;

  // 色相シフトによる固有パレット生成
  final hueShift = (cycle * 25.0) % 360.0;
  final pColor = HSLColor.fromColor(Color(base['p'] as int)).withHue((HSLColor.fromColor(Color(base['p'] as int)).hue + hueShift) % 360).toColor();
  final sColor = HSLColor.fromColor(Color(base['s'] as int)).withHue((HSLColor.fromColor(Color(base['s'] as int)).hue + hueShift) % 360).toColor();
  final bColor = Color(base['b'] as int);
  final aColor = HSLColor.fromColor(Color(base['a'] as int)).withHue((HSLColor.fromColor(Color(base['a'] as int)).hue + hueShift) % 360).toColor();

  final evoP = HSLColor.fromColor(pColor).withLightness((HSLColor.fromColor(pColor).lightness + 0.1).clamp(0.0, 1.0)).withSaturation(1.0).toColor();
  final evoS = HSLColor.fromColor(sColor).withSaturation(1.0).toColor();

  return CharacterSpecies(
    chapter: clampedChap,
    id: id,
    name: name,
    japaneseName: japaneseName,
    category: category,
    description: 'Chapter $clampedChap の相棒。${base['ja']}（${category.label}）。',
    primaryColor: pColor,
    secondaryColor: sColor,
    bellyColor: bColor,
    accessoryColor: aColor,
    evolvedPrimaryColor: evoP,
    evolvedSecondaryColor: evoS,
    coreFeature: base['feat'] as String,
  );
}

/// 48x48 高解像度・2〜2.5頭身 プロシージャルドット絵キャラクターウィジェット
class PixelCharacterWidget extends StatefulWidget {
  final int speciesIndex; // 0..373 (対応チャプター: speciesIndex + 1)
  final CharacterGrowthState growthState;
  final CharacterActionState actionState;
  final Stamp? favoriteStamp;
  final double size;
  final bool isInteractive;
  final VoidCallback? onTap;

  const PixelCharacterWidget({
    super.key,
    required this.speciesIndex,
    this.growthState = CharacterGrowthState.locked,
    this.actionState = CharacterActionState.idle,
    this.favoriteStamp,
    this.size = 48.0,
    this.isInteractive = false,
    this.onTap,
  });

  /// 暗記率（0〜100%）と解放フラグから、厳格に統一された成長状態を算出
  static CharacterGrowthState stateFromRate(double rate, bool isUnlocked) {
    if (!isUnlocked || rate <= 0.0) return CharacterGrowthState.locked; // 0%または未解放は完全単色黒シルエット
    if (rate >= 80.0) return CharacterGrowthState.evolved;             // 80%以上は進化形態
    if (rate >= 50.0) return CharacterGrowthState.healthy;             // 50〜79%は元気な状態
    return CharacterGrowthState.lowHealth;                             // 1〜49%（学習開始後）は元気がない状態
  }

  @override
  State<PixelCharacterWidget> createState() => _PixelCharacterWidgetState();
}

class _PixelCharacterWidgetState extends State<PixelCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  CharacterActionState _runtimeAction = CharacterActionState.idle;

  @override
  void initState() {
    super.initState();
    _runtimeAction = widget.actionState;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant PixelCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actionState != oldWidget.actionState) {
      _runtimeAction = widget.actionState;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isInteractive || widget.growthState == CharacterGrowthState.locked) {
      widget.onTap?.call();
      return;
    }

    setState(() {
      _runtimeAction = CharacterActionState.humming;
    });

    widget.onTap?.call();

    // 2.2秒後に元の状態に戻る
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _runtimeAction = widget.actionState;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = getCharacterSpecies((widget.speciesIndex % kTotalChapterCount) + 1);

    return GestureDetector(
      onTap: widget.isInteractive || widget.onTap != null ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PixelCharacterPainter48(
              species: species,
              growthState: widget.growthState,
              actionState: _runtimeAction,
              favoriteStamp: widget.favoriteStamp,
              animValue: _animController.value,
            ),
          );
        },
      ),
    );
  }
}

/// 48x48 高解像度・2〜2.5頭身 プロシージャル描画ペインター
class _PixelCharacterPainter48 extends CustomPainter {
  final CharacterSpecies species;
  final CharacterGrowthState growthState;
  final CharacterActionState actionState;
  final Stamp? favoriteStamp;
  final double animValue;

  _PixelCharacterPainter48({
    required this.species,
    required this.growthState,
    required this.actionState,
    required this.favoriteStamp,
    required this.animValue,
  });

  static const int kGridSize = 24; // 24x24の論理ドットマトリクス（2px輪郭で48x48キャンバスに精密マッピング）

  @override
  void paint(Canvas canvas, Size size) {
    final double pixelSize = size.width / kGridSize;
    final bool isLocked = growthState == CharacterGrowthState.locked;
    final bool isLowHealth = growthState == CharacterGrowthState.lowHealth;
    final bool isEvolved = growthState == CharacterGrowthState.evolved;

    // アクションによる上下・左右オフセット
    double offsetY = 0.0;
    double offsetX = 0.0;
    bool isBlinking = false;

    if (!isLocked) {
      if (actionState == CharacterActionState.idle) {
        // 呼吸バウンド（元気な時は大きめ、元気ない時は極小）
        final breathAmp = isLowHealth ? 0.3 : 0.8;
        offsetY = math.sin(animValue * math.pi * 2) * breathAmp * pixelSize;
        // 定期的な瞬き（毎周期の最後10%で閉じる）
        isBlinking = animValue > 0.88;
      } else if (actionState == CharacterActionState.walk) {
        // 歩行時の左右スライド＆ステップ
        offsetY = (math.sin(animValue * math.pi * 4).abs()) * 1.2 * pixelSize;
        offsetX = math.sin(animValue * math.pi * 2) * 1.0 * pixelSize;
      } else if (actionState == CharacterActionState.sleep) {
        // 睡眠時のゆったりとした微小呼吸
        offsetY = math.sin(animValue * math.pi * 2) * 0.4 * pixelSize;
      } else if (actionState == CharacterActionState.humming) {
        // 喜びのスイングジャンプ
        offsetY = -(math.sin(animValue * math.pi * 4).abs()) * 2.8 * pixelSize;
        offsetX = math.sin(animValue * math.pi * 2) * 1.2 * pixelSize;
      }
    }

    canvas.save();
    canvas.translate(offsetX, offsetY);

    // 1. カラーパレットの選定
    Color primary;
    Color secondary;
    Color belly;
    Color accessory;
    Color outline = species.outlineColor;

    if (isLocked) {
      // ① シルエット: 完全に均一な黒ベタ塗り（内部の濃淡差・目の区別ゼロ）
      const solidBlack = Color(0xFF2C302E);
      primary = solidBlack;
      secondary = solidBlack;
      belly = solidBlack;
      accessory = solidBlack;
      outline = solidBlack;
    } else if (isLowHealth) {
      // ② 元気がない状態: くすみパステル調（彩度低下・明度微増）
      primary = HSLColor.fromColor(species.primaryColor).withSaturation(0.4).toColor();
      secondary = HSLColor.fromColor(species.secondaryColor).withSaturation(0.4).toColor();
      belly = HSLColor.fromColor(species.bellyColor).withSaturation(0.3).toColor();
      accessory = HSLColor.fromColor(species.accessoryColor).withSaturation(0.4).toColor();
    } else if (isEvolved) {
      // ④ 進化形態: ゴールド・オーロラアクセント＋元特徴カラーの洗練
      primary = species.evolvedPrimaryColor;
      secondary = species.evolvedSecondaryColor;
      belly = const Color(0xFFFFF9C4); // ゴールデンベリー
      accessory = const Color(0xFFFFD700); // 黄金パーツ
    } else {
      // ③ 元気な状態: 鮮やかな標準ビタミンカラー
      primary = species.primaryColor;
      secondary = species.secondaryColor;
      belly = species.bellyColor;
      accessory = species.accessoryColor;
    }

    final matrix = _getSpeciesMatrix24(species.id, isEvolved);

    // 2. ドットマトリクス描画
    final paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < matrix.length && r < kGridSize; r++) {
      final line = matrix[r];
      for (int c = 0; c < line.length && c < kGridSize; c++) {
        final char = line[c];
        if (char == '.') continue;

        final px = c * pixelSize;
        final py = r * pixelSize;

        if (isLocked) {
          paint.color = primary;
          canvas.drawRect(Rect.fromLTWH(px, py, pixelSize + 0.1, pixelSize + 0.1), paint);
          continue;
        }

        switch (char) {
          case 'O': // 輪郭線 (1-2px)
            paint.color = outline;
            break;
          case 'B': // メインボディ
            paint.color = primary;
            break;
          case 'H': // ハイライト
            paint.color = HSLColor.fromColor(primary).withLightness((HSLColor.fromColor(primary).lightness + 0.15).clamp(0.0, 1.0)).toColor();
            break;
          case 'S': // 陰影シェード
            paint.color = secondary;
            break;
          case 'W': // お腹・胸元
            paint.color = belly;
            break;
          case 'A': // 耳・角・ヘタ・アクセサリ
            paint.color = accessory;
            break;
          case 'E': // 瞳
            if (actionState == CharacterActionState.sleep || isBlinking) {
              paint.color = outline; // 閉じ目
            } else if (isLowHealth) {
              paint.color = const Color(0xFF455A64); // しょんぼり瞳
            } else {
              paint.color = const Color(0xFF1A1A1A); // 大きな黒目
            }
            break;
          case 'P': // 瞳のハイライト光 ✨
            if (actionState == CharacterActionState.sleep || isBlinking || isLowHealth) {
              paint.color = outline;
            } else {
              paint.color = Colors.white;
            }
            break;
          case 'M': // 口・鼻・くちばし
            paint.color = isLowHealth ? const Color(0xFF8D6E63) : const Color(0xFFFF7043);
            break;
          case 'C': // ほっぺチーク
            paint.color = isLowHealth ? Colors.transparent : const Color(0xFFFF8A80).withAlpha(180);
            break;
          case 'F': // 手足
            paint.color = secondary;
            break;
          case 'T': // 尻尾・翼
            paint.color = accessory;
            break;
          default:
            paint.color = primary;
        }

        // 閉じ目または睡眠時の表現
        if ((char == 'E' || char == 'P') && (actionState == CharacterActionState.sleep || isBlinking)) {
          canvas.drawRect(
            Rect.fromLTWH(px, py + pixelSize * 0.45, pixelSize, pixelSize * 0.25),
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

    // 3. 進化形態のパーツ（王冠・翼・オーラ星粒子）
    if (isEvolved) {
      _drawEvolutionDecorations(canvas, pixelSize, animValue);
    }

    // 4. アクション状態のエフェクト
    if (!isLocked) {
      if (isLowHealth) {
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
    if (favoriteStamp != null && !isLocked) {
      _drawChestBadge(canvas, pixelSize, favoriteStamp!);
    }

    canvas.restore();
  }

  /// 進化形態の豪華パーツ（王冠・羽ばたく翼・オーラ星粒子）
  void _drawEvolutionDecorations(Canvas canvas, double pixelSize, double anim) {
    final goldPaint = Paint()..color = const Color(0xFFFFD700);
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    final wingPaint = Paint()..color = const Color(0xFFE1F5FE).withAlpha(230);
    final starPaint = Paint()..color = const Color(0xFFFFF9C4);

    // 1. 黄金の王冠 (頭上: col 9-14, row 0-2)
    canvas.drawRect(Rect.fromLTWH(9 * pixelSize, 0 * pixelSize, 1.2 * pixelSize, 1.5 * pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(11.5 * pixelSize, 0 * pixelSize, 1.2 * pixelSize, 1.8 * pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(14 * pixelSize, 0 * pixelSize, 1.2 * pixelSize, 1.5 * pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(9 * pixelSize, 1.5 * pixelSize, 6.2 * pixelSize, 1.2 * pixelSize), goldPaint);
    canvas.drawRect(Rect.fromLTWH(11.6 * pixelSize, 1.5 * pixelSize, 1.0 * pixelSize, 1.0 * pixelSize), rubyPaint);

    // 2. 羽ばたく天使の翼 (左右)
    final wingFlap = math.sin(anim * math.pi * 4) * 0.8;
    // 左翼
    canvas.drawRect(Rect.fromLTWH(1 * pixelSize, (8 + wingFlap) * pixelSize, 3 * pixelSize, 4 * pixelSize), wingPaint);
    canvas.drawRect(Rect.fromLTWH(2 * pixelSize, (7 + wingFlap) * pixelSize, 2 * pixelSize, 2 * pixelSize), wingPaint);
    // 右翼
    canvas.drawRect(Rect.fromLTWH(20 * pixelSize, (8 + wingFlap) * pixelSize, 3 * pixelSize, 4 * pixelSize), wingPaint);
    canvas.drawRect(Rect.fromLTWH(20 * pixelSize, (7 + wingFlap) * pixelSize, 2 * pixelSize, 2 * pixelSize), wingPaint);

    // 3. オーラ星粒子 ✨ (周囲に浮遊)
    final p1Y = (4 + math.sin(anim * math.pi * 2) * 2.5) * pixelSize;
    final p2Y = (16 + math.cos(anim * math.pi * 2) * 2.5) * pixelSize;
    final p3Y = (8 + math.sin(anim * math.pi * 2 + 1) * 2.0) * pixelSize;
    canvas.drawCircle(Offset(3 * pixelSize, p1Y), pixelSize * 0.7, starPaint);
    canvas.drawCircle(Offset(21 * pixelSize, p2Y), pixelSize * 0.7, starPaint);
    canvas.drawCircle(Offset(22 * pixelSize, p3Y), pixelSize * 0.5, starPaint);
  }

  /// 汗マーク 💧
  void _drawSweatDrop(Canvas canvas, double pixelSize, double anim) {
    final sweatPaint = Paint()..color = const Color(0xFF42A5F5);
    final dropY = (6 + (anim * 3) % 4) * pixelSize;
    canvas.drawCircle(Offset(20 * pixelSize, dropY), pixelSize * 0.8, sweatPaint);
  }

  /// Zzz 浮遊エフェクト
  void _drawZzzEffect(Canvas canvas, double pixelSize, double anim) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final progress = anim;
    final alpha = (math.sin(progress * math.pi) * 255).clamp(0, 255).toInt();

    final zOffset = Offset(
      (17 + progress * 3) * pixelSize,
      (6 - progress * 5) * pixelSize,
    );

    textPainter.text = TextSpan(
      text: 'z',
      style: TextStyle(
        fontSize: pixelSize * 4,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5C6BC0).withAlpha(alpha),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, zOffset);
  }

  /// 音符 ♪ ♫ エフェクト
  void _drawMusicNotes(Canvas canvas, double pixelSize, double anim) {
    final notePaint = Paint()..color = const Color(0xFFFF4081);
    final noteY = (4 - math.sin(anim * math.pi * 2).abs() * 4) * pixelSize;
    final noteX1 = (4 + math.sin(anim * math.pi * 4) * 2.0) * pixelSize;
    final noteX2 = (19 - math.sin(anim * math.pi * 4) * 2.0) * pixelSize;

    // 音符1 ♪
    canvas.drawCircle(Offset(noteX1, noteY), pixelSize * 1.0, notePaint);
    canvas.drawRect(Rect.fromLTWH(noteX1 + pixelSize * 0.5, noteY - pixelSize * 2.5, pixelSize * 0.5, pixelSize * 2.5), notePaint);

    // 音符2 ♫
    canvas.drawCircle(Offset(noteX2, noteY + pixelSize * 1.5), pixelSize * 0.9, notePaint);
    canvas.drawRect(Rect.fromLTWH(noteX2 + pixelSize * 0.4, noteY - pixelSize * 1.0, pixelSize * 0.4, pixelSize * 2.5), notePaint);
  }

  Color _getStampMainColor(Stamp stamp) {
    switch (stamp.colorPaletteId % 16) {
      case 0: return const Color(0xFF5F9E98); // エメラルド
      case 1: return const Color(0xFFE58A9E); // サクラピンク
      case 2: return const Color(0xFFECA882); // アンバーオレンジ
      case 3: return const Color(0xFF5B92E5); // オーシャンスカイ
      case 4: return const Color(0xFF9C27B0); // アメジスト
      case 5: return const Color(0xFFE91E63); // ルビーレッド
      case 6: return const Color(0xFF4CAF50); // フォレストグリーン
      case 7: return const Color(0xFFFFB300); // サニーレモン
      case 8: return const Color(0xFF00BCD4); // ターコイズ
      case 9: return const Color(0xFF3F51B5); // ラピスラズリ
      case 10: return const Color(0xFF795548); // チョコブラウン
      case 11: return const Color(0xFF607D8B); // スレートグレー
      case 12: return const Color(0xFFFF5722); // フレイムバーミリオン
      case 13: return const Color(0xFF8BC34A); // ライムグリーン
      case 14: return const Color(0xFF673AB7); // ロイヤルパープル
      case 15: return const Color(0xFFFF9800); // ディープオレンジ
      default: return const Color(0xFF5F9E98);
    }
  }

  /// お気に入りスタンプ胸バッジ合成描画 (F-14: 装備中スタンプのメインカラーを動的反映)
  void _drawChestBadge(Canvas canvas, double pixelSize, Stamp stamp) {
    final badgeCenter = Offset(12 * pixelSize, 14 * pixelSize);
    final double badgeRadius = pixelSize * 2.2;

    // 1. ゴールドバッジ外枠
    final goldPaint = Paint()..color = const Color(0xFFFFD700);
    final borderPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(badgeCenter, badgeRadius, goldPaint);
    canvas.drawCircle(badgeCenter, badgeRadius, borderPaint);

    // 2. 装備中スタンプのメインカラーを胸元バッジに動的反映
    final stampColor = _getStampMainColor(stamp);
    final motifPaint = Paint()..color = stampColor;
    final double miniPx = pixelSize * 0.5;

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

  /// 24x24ドット（48x48精密マッピング）の2〜2.5頭身種族マトリクス
  List<String> _getSpeciesMatrix24(int speciesId, bool isEvolved) {
    switch (speciesId % 24) {
      // 1. 🐾 動物系
      case 0: // ミケネコ (Kitty)
        return [
          '........................',
          '..AAA..............AAA..',
          '..AAAA............AAAA..',
          '..AOSSA..........ASSOA..',
          '..AOOBBBAAAAAAAABBBOA...',
          '..AOBBBBBBBBBBBBBBBOA...',
          '..OBBBBBBBBBBBBBBBBBO...',
          '..OBBEEBBBBBBBBEEBBBO...',
          '..OBBPEBBBMIMBBPEBBBO...',
          '..OBBBBBBBMCMMBBBBBBO...',
          '..OOBBBBCBBBBBCCBBBOO...',
          '...OOBBBBBBBBBBBBBOO....',
          '....OOOOOOOOOOOOOOO.....',
          '.....OBBBWWWWWWBBBO.TT..',
          '....OBBBBWWWWWWBBBBO.T..',
          '....OBBBBWWWWWWBBBBO.T..',
          '....OBBBBBBBBBBBBBBO.TT.',
          '....OBBBBBBBBBBBBBBO..T.',
          '.....OBBBBBBBBBBBBO..TT.',
          '......OOOOOOOOOOOO......',
          '.......OFFO...OFFO......',
          '.......OFFO...OFFO......',
          '........OO.....OO.......',
          '........................',
        ];
      case 1: // しばいぬ (Puppy)
        return [
          '........................',
          '...AAA............AAA...',
          '..AAAAA..........AAAAA..',
          '..AOOSSA........ASSOOA..',
          '..AOBBBBAAAAAAAABBBBOA..',
          '..OBBBBBBBBBBBBBBBBBO...',
          '..OBBBBBBBBBBBBBBBBBO...',
          '..OBBEEBBBBBBBBEEBBBO...',
          '..OBBPEBBBBMIBBPEBBBO...',
          '..OBBBBBBBMIMMBBBBBBO...',
          '..OOBBCBBBBBBBBCBBOO....',
          '...OOBBBBBBBBBBBBBOO....',
          '....OOOOOOOOOOOOOOO.....',
          '.....OBBBWWWWWWBBBO..TT.',
          '....OBBBBWWWWWWBBBBO.TT.',
          '....OBBBBWWWWWWBBBBO.T..',
          '....OBBBBBBBBBBBBBBO.TT.',
          '....OBBBBBBBBBBBBBBO..T.',
          '.....OBBBBBBBBBBBBO.....',
          '......OOOOOOOOOOOO......',
          '.......OFFO...OFFO......',
          '.......OFFO...OFFO......',
          '........OO.....OO.......',
          '........................',
        ];
      case 2: // ロップウサギ (Bunny)
        return [
          '........................',
          '..AAA..............AAA..',
          '..AAAA............AAAA..',
          '..ASSOA..........AOSSA..',
          '..ASSOOBBBBBBBBOOSSOA...',
          '..ASSOBBBBBBBBBBOOSSA...',
          '..ASSOBEEBBBBEEBOOSSA...',
          '..AOSOBPEBBBBPEBOOSSA...',
          '..AOSOBBBMIMBBBOOSSA....',
          '..AOOBBBCBBBBCBBOOO.....',
          '...OOBBBBBBBBBBBBO......',
          '....OOOOOOOOOOOOOO......',
          '.....OBBBWWWWWWBBBO.....',
          '....OBBBBWWWWWWBBBBO....',
          '....OBBBBWWWWWWBBBBO.T..',
          '....OBBBBWWWWWWBBBBO.TT.',
          '....OBBBBBBBBBBBBBBO....',
          '.....OBBBBBBBBBBBBO.....',
          '......OOOOOOOOOOOO......',
          '.......OFFO...OFFO......',
          '.......OFFO...OFFO......',
          '........OO.....OO.......',
          '........................',
          '........................',
        ];
      case 3: // こぐま (Bear)
        return [
          '........................',
          '..AAAA............AAAA..',
          '.AAAAAA..........AAAAAA.',
          '.AOSSOA..........AOSSOA.',
          '.AOOBBBBAAAAAAAABBBBOA..',
          '..OBBBBBBBBBBBBBBBBBO...',
          '..OBBBBBBBBBBBBBBBBBO...',
          '..OBBEEBBBBBBBBEEBBBO...',
          '..OBBPEBBBMIMBBPEBBBO...',
          '..OBBBBBBBMIMMBBBBBBO...',
          '..OOBBCBBBMIMBBCBBOO....',
          '...OOBBBBBBBBBBBBBOO....',
          '....OOOOOOOOOOOOOOO.....',
          '....OBBBBBWWWWBBBBBO....',
          '...OBBBBBBWWWWBBBBBBO...',
          '...OBBBBBBWWWWBBBBBBO...',
          '...OBBBBBBBBBBBBBBBBO...',
          '...OBBBBBBBBBBBBBBBBO...',
          '....OBBBBBBBBBBBBBBO....',
          '.....OOOOOOOOOOOOOO.....',
          '......OFFO....OFFO......',
          '......OFFO....OFFO......',
          '.......OO......OO.......',
          '........................',
        ];
      case 4: // こぎつね (Fox)
        return [
          '........................',
          '..AAAA............AAAA..',
          '.AAAAAA..........AAAAAA.',
          '.AOSSSOA........AOSSSOA.',
          '.AOOBBBBBAAAAAABBBBBOA..',
          '..OBBBBBBBBBBBBBBBBBO...',
          '..OBBEEBBBBBBBBEEBBBO...',
          '..OBBPEBBBMIMBBPEBBBO...',
          '..OBWWBBBBMCMMBBBWBOO...',
          '..OOBWWWCBBBBCWWWOO.TT..',
          '...OOBBBWWWWWBBBBO.TTT..',
          '....OOOOOOOOOOOOOO.TTT..',
          '.....OBBBWWWWWWBBBOTTT..',
          '....OBBBBWWWWWWBBBOTTT..',
          '....OBBBBWWWWWWBBBOTT...',
          '....OBBBBBBBBBBBBBOT....',
          '.....OBBBBBBBBBBBBO.....',
          '......OOOOOOOOOOOO......',
          '.......OFFO...OFFO......',
          '.......OFFO...OFFO......',
          '........OO.....OO.......',
          '........................',
          '........................',
          '........................',
        ];
      case 5: // パンダ (Panda)
        return [
          '........................',
          '..AAAA............AAAA..',
          '.AAAAAA..........AAAAAA.',
          '.AOSSOA..........AOSSOA.',
          '.AOOBBBBAAAAAAAABBBBOA..',
          '..OBBBBBBBBBBBBBBBBBO...',
          '..OBBSSBBBBBBBBSSBBBO...',
          '..OBSSEBBBBBBBBSSEBBO...',
          '..OBSPEBBBMIMBBSPEBBO...',
          '..OBBSSBBBMCMMBBSSBBO...',
          '..OOBBCBBBBBBBBCBBOO....',
          '...OOBBBBBBBBBBBBBOO....',
          '....OOOOOOOOOOOOOOO.....',
          '....OSSSBBWWWWBBSSSO....',
          '...OSSSSSBWWWWBBSSSSO...',
          '...OSSSSSBWWWWBBSSSSO...',
          '...OSSSBBBBBBBBBBSSSO...',
          '....OBBBBBBBBBBBBBBO....',
          '.....OBBBBBBBBBBBBO.....',
          '......OOOOOOOOOOOO......',
          '......OFFO....OFFO......',
          '......OFFO....OFFO......',
          '.......OO......OO.......',
          '........................',
        ];

      // 2. 🕊️ 鳥・飛行系
      case 6: // ヒヨコ (Chicky)
        return [
          '........................',
          '..........AAAA..........',
          '.........AAAAAA.........',
          '........OOBBBBOO........',
          '.......OBBBBBBBBO.......',
          '......OBBBBBBBBBBO......',
          '.....OBBBEEBBEEBBBO.....',
          '.....OBBBPEBMPEBBBO.....',
          '.....OBBBBCMMMCBBBO.....',
          '......OBBBBBBBBBBO......',
          '.......OOBBBBBBOO.......',
          '......OBBBBBBBBBBO......',
          '.....OBBBWWWWWWBBBO.....',
          '....TOBBBWWWWWWBBBOT....',
          '....TOBBBWWWWWWBBBOT....',
          '....TOBBBBBBBBBBBBOT....',
          '.....TOBBBBBBBBBBO......',
          '......OOOOOOOOOO........',
          '........OFF..FF.........',
          '.......OFFF..FFF........',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
        ];
      case 7: // ペンギン (Penguin)
        return [
          '........................',
          '........OOOOOOOO........',
          '.......OBBBBBBBBO.......',
          '......OBBBBBBBBBBO......',
          '.....OBBBEEBBEEBBBO.....',
          '.....OBBBPEBMPEBBBO.....',
          '.....OBBBSCMMCSBBBO.....',
          '.....OBBBSSMMSSBBBO.....',
          '......OBBBBBBBBBBO......',
          '.....TOBBWWWWWWBBOT.....',
          '....TTOBBWWWWWWBBOTT....',
          '....TTOBBWWWWWWBBOTT....',
          '....TTOBBWWWWWWBBOTT....',
          '.....TOBBWWWWWWBBOT.....',
          '......OBBWWWWWWBBO......',
          '.......OBBBBBBBBO.......',
          '........OOOOOOOO........',
          '........OFF..FF.........',
          '.......OFFF..FFF........',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 8: // フクロウ (Owl)
        return [
          '........................',
          '...AA..............AA...',
          '..AAAA............AAAA..',
          '..AOSSOA........AOSSOA..',
          '..AOOBBBAAAAAAAABBBOA...',
          '..OBBOOOBBBBBBOOOBBO....',
          '..OBOEEEOBBBBOEEEOBO....',
          '..OBOEPEOBMMOBEPEOBO....',
          '..OBOEEEOBMMOBEEEOBO....',
          '..OBBOOOBBCBBBOOOBBO....',
          '...OOBBBBBBBBBBBBBO.....',
          '....OOOOOOOOOOOOOO......',
          '....TOBBWWWWWWBBOT......',
          '...TTOBBWWWWWWBBOTT.....',
          '...TTOBBWWWWWWBBOTT.....',
          '...TTOBBBBBBBBBBOTT.....',
          '....TOBBBBBBBBBBOT......',
          '.....OOOOOOOOOOOO.......',
          '.......OFF....OFF.......',
          '......OFFF....OFFF......',
          '.......OO......OO.......',
          '........................',
          '........................',
          '........................',
        ];

      // 3. 🐟 水棲系
      case 9: // あまがえる (Froggy)
        return [
          '........................',
          '..OOO..............OOO..',
          '.OEEEO............OEEEO.',
          '.OEPEO...AAAAAA...OEPEO.',
          '.OEEEO..ABBBBBBA..OEEEO.',
          '..OOO.ABBBBBBBBBBA.OOO..',
          '....OBBBBBBBBBBBBBBO....',
          '...OBBBBBBBBBBBBBBBBO...',
          '...OBBCBBBMIMMMBCBBBO...',
          '...OBBBBBBBBBBBBBBBBO...',
          '....OOBBBBBBBBBBBBBOO...',
          '.....OOOOOOOOOOOOOO.....',
          '.....OBBBWWWWWWBBBO.....',
          '....OBBBBWWWWWWBBBBO....',
          '...FOBBBBWWWWWWBBBBOF...',
          '...FOBBBBBBBBBBBBBBOF...',
          '....OBBBBBBBBBBBBBBO....',
          '.....OOOOOOOOOOOOOO.....',
          '......OFFO....OFFO......',
          '.....OFFFO....OFFFO.....',
          '......OO........OO......',
          '........................',
          '........................',
          '........................',
        ];
      case 10: // クラゲぼうや (Jelly)
        return [
          '........................',
          '........OOOOOOOO........',
          '......OOBBBBBBBBOO......',
          '.....OBBBBBBBBBBBBO.....',
          '....OBBBBBBBBBBBBBBBO...',
          '...OBBEEBBBBBBBBEEBBBO..',
          '...OBBPEBBBMIMBBPEBBBO..',
          '...OBBCBBBBBBBBCBBBOO...',
          '...OOBBBBBBBBBBBBBBOO...',
          '....OOOOOOOOOOOOOOOO....',
          '.....O..O..O..O..O......',
          '.....B..B..B..B..B......',
          '.....S..S..S..S..S......',
          '.....B..B..B..B..B......',
          '.....S..S..S..S..S......',
          '.....B..B..B..B..B......',
          '......S..S..S..S..S.....',
          '.......O..O..O..O.......',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 11: // タコまる (Octy)
        return [
          '........................',
          '........OOOOOOOO........',
          '......OOBBBBBBBBOO......',
          '.....OBBBBBBBBBBBBO.....',
          '....OBBBBBBBBBBBBBBBO...',
          '...OBBEEBBBBBBBBEEBBBO..',
          '...OBBPEBBBOOOOBPEBBBO..',
          '...OBBCBBBOOMMOOBBBOO...',
          '...OOBBBBBBOOOOBBBBOO...',
          '....OOOOOOOOOOOOOOOO....',
          '...OFF..FF..FF..FF......',
          '..OFFF.OFF.OFF.OFFF.....',
          '..OFF..OFF.OFF..OFF.....',
          '..OO...OO..OO...OO......',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];

      // 4. 🌿 植物系
      case 12: // プチトマト (Tomaty)
        return [
          '........................',
          '.........AAAAA..........',
          '........AAAAAAA.........',
          '.......AA.AAA.AA........',
          '......OOBBBBBBBOO.......',
          '....OOBBBBBBBBBBBOO.....',
          '...OBBEEBBBBBBBBEEBBO...',
          '...OBBPEBBBMIMBBPEBBO...',
          '...OBBBBBBBMCMMBBBBBO...',
          '...OBBCBBBBBBBBCBBBOO...',
          '...OOBBBBBBBBBBBBBBOO...',
          '....OBBBBBBBBBBBBBBBO...',
          '....OBBBBBBBBBBBBBBBO...',
          '....OBBBBBBBBBBBBBBBO...',
          '.....OBBBBBBBBBBBBO.....',
          '......OOOOOOOOOOOO......',
          '.......OFFO...OFFO......',
          '.......OFFO...OFFO......',
          '........OO.....OO.......',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 13: // サボテンくん (Cactus)
        return [
          '........................',
          '...........AA...........',
          '..........AAAA..........',
          '........OOOOOOOO........',
          '..OO...OBBBBBBBBO...OO..',
          '.OBBO..OBBBBBBBBO..OBBO.',
          '.OBBO.OBBEEBBEEBBO.OBBO.',
          '.OBBO.OBBPEBMPEBBO.OBBO.',
          '.OBBO.OBBBCMMMCBBO.OBBO.',
          '..OOO.OBBBBBBBBBBO.OOO..',
          '....OOOBBBBBBBBBBOOO....',
          '.....OBBBBBBBBBBBO......',
          '.....OBBBBBBBBBBBO......',
          '.....OBBBBBBBBBBBO......',
          '.....OBBBBBBBBBBBO......',
          '......OOOOOOOOOO........',
          '.......OFF....OFF.......',
          '.......OFF....OFF.......',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 14: // キノコちゃん (Shroom)
        return [
          '........................',
          '........OOOOOOOO........',
          '......OOBBWWWWBBBOO.....',
          '....OOBBBBBWWBBBBBBOO...',
          '...OBBBWWBBBBBBWWBBBBO..',
          '..OBBBBBBBWWBBBBBBBBBBO.',
          '..OBWWBBBBBBBBBBBBWWBBBO',
          '..OOOOOOOOOOOOOOOOOOOOOO',
          '......OBBEEBEEBBO.......',
          '......OBBPEBPEBBO.......',
          '......OBBCBMBMCBBO......',
          '......OBBBBBBBBBBO......',
          '.......OBBBWWBBBO.......',
          '.......OBBBWWBBBO.......',
          '........OOOOOOOO........',
          '.......OFFO..OFFO.......',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];

      // 5. 👾 モンスター系
      case 15: // ぷるぷるスライム (Slimey)
        return [
          '........................',
          '...........AA...........',
          '..........AAAA..........',
          '.........OOBBBO.........',
          '........OBBBBBBO........',
          '.......OBBBBBBBBO.......',
          '......OBBBBBBBBBBO......',
          '.....OBBEEBBBBEEBBBO....',
          '.....OBBPEBBBMPEBBBO....',
          '....OBBBBCBMMBCBBBBOO...',
          '...OOBBBBBBBBBBBBBBBOO..',
          '..OBBBBBBBBBBBBBBBBBBBO.',
          '..OBBBBBBBBBBBBBBBBBBBO.',
          '...OOOOOOOOOOOOOOOOOO...',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 16: // おばけちゃん (Ghosty)
        return [
          '........................',
          '........OOOOOOOO........',
          '......OOBBBBBBBBOO......',
          '.....OBBBBBBBBBBBBO.....',
          '....OBBBBBBBBBBBBBBBO...',
          '...OBBEEBBBBBBBBEEBBBO..',
          '...OBBPEBBBMIMBBPEBBBO..',
          '...OBBCBBBBBBBBCBBBOO...',
          '...OOBBBBBBBBBBBBBBOO...',
          '....OBBBBBBBBBBBBBBBO...',
          '....OBBBBBBBBBBBBBBBO...',
          '....OBBBBBBBBBBBBBBBO...',
          '.....OBB.OBB.OBB.OBO....',
          '......OO..OO..OO..O.....',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 17: // コバコモドキ (Mimic)
        return [
          '........................',
          '......OOOOOOOOOOOO......',
          '.....OBBBBBBBBBBBBO.....',
          '....OBBBBAAAABBBBBO.....',
          '....OBBBBAAAABBBBBO.....',
          '....OOOOOOOOOOOOOOO.....',
          '....OMMMMMMMMMMMMMO.....',
          '....OMMEEEEMMEEEEMO.....',
          '....OMMEPEOMMEPEOMM.....',
          '....OMMMMMMMMMMMMMO.....',
          '....OBBBBAAAABBBBBO.....',
          '.....OBBBBBBBBBBBBO.....',
          '......OOOOOOOOOOOO......',
          '.......OFFO..OFFO.......',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];

      // 6. 🐲 ファンタジー系
      case 18: // プチドラゴン (Drake)
        return [
          '........................',
          '..AA...AAAAAA...AA......',
          '..AAAA.AAAAAA.AAAA......',
          '..AOOSSAAAAAASSOOA......',
          '..AOOBBBBBBBBBBBOA......',
          '..OBBBBBBBBBBBBBBO..TT..',
          '..OBBEEBBBBBBEEBBO.TTT..',
          '..OBBPEBBBMIBPEBBO.TT...',
          '..OBBCBBBMIMBBCBBO.TT...',
          '..OOBBBBBBBBBBBBBO.TTT..',
          '...OOBBBBBBBBBBBOO.TT...',
          '....OOOOOOOOOOOOO..TT...',
          '.....OBBBWWWWBBBO...T...',
          '....OBBBBWWWWBBBBO......',
          '....OBBBBWWWWBBBBO......',
          '....OBBBBBBBBBBBBO......',
          '.....OBBBBBBBBBBO.......',
          '......OOOOOOOOOO........',
          '.......OFFO..OFFO.......',
          '.......OFFO..OFFO.......',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
        ];
      case 19: // ユニコーン (Unicorn)
        return [
          '...........AA...........',
          '..........AAAA..........',
          '..AAA....AAAAAA...AAA...',
          '..AAAA..AOSSSOA..AAAA...',
          '..AOOSSAOBBBBBOASSOOA...',
          '..AOOBBBBBBBBBBBOA......',
          '..OBBBBBBBBBBBBBBO......',
          '..OBBEEBBBBBBEEBBO......',
          '..OBBPEBBBMIBPEBBO.TT...',
          '..OBBCBBBMIMBBCBBO.TTT..',
          '..OOBBBBBBBBBBBBBO.TTT..',
          '...OOBBBBBBBBBBBOO.TT...',
          '....OOOOOOOOOOOOO...T...',
          '.....OBBBWWWWBBBO...T...',
          '....OBBBBWWWWBBBBO......',
          '....OBBBBWWWWBBBBO......',
          '....OBBBBBBBBBBBBO......',
          '.....OBBBBBBBBBBO.......',
          '......OOOOOOOOOO........',
          '.......OFFO..OFFO.......',
          '.......OFFO..OFFO.......',
          '........OO....OO........',
          '........................',
          '........................',
        ];

      // 7. 🧚 人型・妖精系
      case 20: // もりの妖精 (Pixie)
        return [
          '........................',
          '..........AAAA..........',
          '.........AAAAAA.........',
          '........AAOSSOAA........',
          '...AA..AOBBBBBBOA..AA...',
          '..AAAAOBBBBBBBBBBOAAAA..',
          '..AOOBBEEBBBBEEBBOOA....',
          '...OBBPEBBBMIBPEBBO.....',
          '...OBBCBBBMIMBBCBBO.....',
          '....OOBBBBBBBBBBBO......',
          '....TTOOBBBBBBBOOTT.....',
          '...TTT.OBBWWWBBO.TTT....',
          '...TT.OBBBWWWBBO..TT....',
          '......OBBBWWWBBO........',
          '.......OBBBBBBBO........',
          '........OOOOOOO.........',
          '.........OFFOFF.........',
          '.........OFFOFF.........',
          '..........OO.OO.........',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 21: // ちび勇者 (Hero)
        return [
          '........................',
          '........AAAAAAAA........',
          '.......AAAAAAAAAA.......',
          '......AAOSSSSSSOAA......',
          '......AOBBBBBBBBOA......',
          '......OBBEEBBEEBBO......',
          '......OBBPEBPEBBOO......',
          '......OBBCBMBMCBBO......',
          '.......OBBBBBBBBO.......',
          '....TOOBBBWWWWBBBO......',
          '...TTOOBBBWWWWBBBOAA....',
          '...TTOOBBBWWWWBBBOAAAA..',
          '...TTOOBBBBBBBBBBO.AA...',
          '....TOOBBBBBBBBBBO......',
          '......OOOOOOOOOO........',
          '.......OFFO..OFFO.......',
          '.......OFFO..OFFO.......',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];

      // 8. 🤖 特殊・コズミック系
      case 22: // レトロロボ (Robo)
        return [
          '........................',
          '...........AA...........',
          '...........AA...........',
          '........OOOOOOOO........',
          '.......OSSSSSSSSO.......',
          '......OSBBBBBBBBSS......',
          '.....OSBEEBBBBEEBSO.....',
          '.....OSBPEBMIMPEBSO.....',
          '.....OSBBBMMMMBBBSO.....',
          '.....OSSSSSSSSSSSSO.....',
          '......O..O....O..O......',
          '.....OSBBWWWWWWBSO......',
          '....FOSBBWWWWWWBSOF.....',
          '....FOSBBWWWWWWBSOF.....',
          '.....OSBBBBBBBBBSO......',
          '......OSSSSSSSSSO.......',
          '.......OFFO..OFFO.......',
          '.......OFFO..OFFO.......',
          '........OO....OO........',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
      case 23: // ほしの子 (Starlet)
      default:
        return [
          '........................',
          '...........AA...........',
          '..........AAAA..........',
          '.........AAAAAA.........',
          '..AAAA..OOBBBBOO..AAAA..',
          '...AAAAOBBBBBBBBOAAAA...',
          '....AOBBEEBBEEBBBOA.....',
          '....OBBBPEBMPEBBBBO.....',
          '....OBBBCBMMMCBBBBO.....',
          '....AOBBBBBBBBBBBOA.....',
          '...AAAAOBBWWWWBOAAAA....',
          '..AAAA..OBWWWWBO..AAAA..',
          '.........OBBBBO.........',
          '........OBB..BBO........',
          '.......OBBO..OBBO.......',
          '......OBB......BBO......',
          '......OO........OO......',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
          '........................',
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _PixelCharacterPainter48 oldDelegate) {
    return oldDelegate.species.id != species.id ||
        oldDelegate.growthState != growthState ||
        oldDelegate.actionState != actionState ||
        oldDelegate.favoriteStamp?.id != favoriteStamp?.id ||
        oldDelegate.animValue != animValue;
  }
}
