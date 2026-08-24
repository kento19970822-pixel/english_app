// コード管理番号: VER-20260824-30
import 'dart:math';
import 'package:drift/drift.dart';
import '../db/app_database.dart';

/// スタンプ生成・抽選・Phase UP サービス
class StampService {
  final AppDatabase database;
  static final Random _random = Random();

  StampService({required this.database});

  /// 今日の日付文字列（YYYY-MM-DD）を取得
  String getTodayStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// 初期起動時にPhase 1スタンプ（20個）を自動生成・登録
  Future<void> ensureInitialized() async {
    final allStamps = await database.getAllStamps();
    if (allStamps.isEmpty) {
      await generateAndInsertPhaseStamps(1);
    }
  }

  /// 指定Phaseのスタンプ（20個）を生成してDBへ挿入
  Future<List<StampsCompanion>> generateAndInsertPhaseStamps(int phase) async {
    final list = _buildStampsForPhase(phase);
    await database.insertStamps(list);
    return list;
  }

  /// 1日1回のゲーム完了時にスタンプを判定・授与
  /// （すでに今日スタンプを獲得済みの場合は null を返却）
  Future<Stamp?> checkAndAwardDailyStamp() async {
    await ensureInitialized();

    final todayStr = getTodayStr();
    final todayRecord = await database.getDailyRecord(todayStr);

    // 今日すでにスタンプが押印されている場合はスキップ
    if (todayRecord.appliedStampId != null && todayRecord.appliedStampId!.isNotEmpty) {
      return null;
    }

    // 1. ユーザーの現在の学習進捗状況を集計
    final streak = await database.calculateStreak();
    final allDailyRecords = await database.select(database.dailyRecords).get();
    final totalDays = allDailyRecords.where((r) => r.playedCount > 0 || r.memorizedCount > 0).length;

    final allWords = await database.select(database.words).get();
    final memorizedCount = allWords.where((w) => w.isMemorized).length;

    final allChapters = await database.select(database.chapterProgresses).get();
    final clearedChapters = allChapters.where((c) => c.isCleared).length;

    // 2. 全スタンプを取得し、条件合致するスタンプを抽出
    final allStamps = await database.getAllStamps();

    // 獲得条件を満たしているスタンプ（条件なし or 条件値達成済み）
    bool isEligible(Stamp s) {
      switch (s.conditionType) {
        case 'streak_days':
          return streak >= s.conditionValue;
        case 'total_days':
          return totalDays >= s.conditionValue;
        case 'memorized_count':
          return memorizedCount >= s.conditionValue;
        case 'cleared_chapters':
          return clearedChapters >= s.conditionValue;
        case 'none':
        default:
          return true;
      }
    }

    final eligibleStamps = allStamps.where(isEligible).toList();
    final eligibleLockedStamps = eligibleStamps.where((s) => !s.isUnlocked).toList();

    Stamp targetStamp;

    if (eligibleLockedStamps.isNotEmpty) {
      // 3. 条件を満たしている未獲得スタンプの中から、レア度に応じた重み付け抽選
      // (Normal: 70%, Rare: 22%, Super Rare: 8%)
      targetStamp = _selectByRarityWeight(eligibleLockedStamps);
    } else if (eligibleStamps.isNotEmpty) {
      // 条件達成済みの未獲得スタンプがない場合は、条件達成済みの獲得済みスタンプから選出（未達成スタンプは勝手に解放しない）
      targetStamp = _selectByRarityWeight(eligibleStamps);
    } else {
      // 万が一のフォールバック（初期スタンプ等）
      final defaultStamps = allStamps.where((s) => s.conditionType == 'none').toList();
      targetStamp = defaultStamps.isNotEmpty
          ? defaultStamps[_random.nextInt(defaultStamps.length)]
          : allStamps.first;
    }

    // 4. スタンプの解放状態更新（未解放の場合のみ解放） & カレンダーマスへ押印
    final now = DateTime.now();
    if (!targetStamp.isUnlocked) {
      await database.unlockStamp(targetStamp.id, now);
    }
    await database.setDailyAppliedStamp(todayStr, targetStamp.id);

    // 最新のスタンプ情報を再取得して返却
    final updatedStamps = await database.getAllStamps();
    return updatedStamps.firstWhere((s) => s.id == targetStamp.id, orElse: () => targetStamp);
  }

  /// レア度に応じた重み付け抽選
  Stamp _selectByRarityWeight(List<Stamp> candidates) {
    if (candidates.length == 1) return candidates.first;

    final superRares = candidates.where((s) => s.rarity == 'super_rare').toList();
    final rares = candidates.where((s) => s.rarity == 'rare').toList();
    final normals = candidates.where((s) => s.rarity == 'normal').toList();

    final roll = _random.nextInt(100); // 0〜99

    if (roll < 8 && superRares.isNotEmpty) {
      // 8%: Super Rare
      return superRares[_random.nextInt(superRares.length)];
    } else if (roll < 30 && rares.isNotEmpty) {
      // 22%: Rare
      return rares[_random.nextInt(rares.length)];
    } else if (normals.isNotEmpty) {
      // 70%: Normal
      return normals[_random.nextInt(normals.length)];
    }

    // いずれかの候補にヒットしなかった場合は全体からランダム
    return candidates[_random.nextInt(candidates.length)];
  }

  /// 現在のPhaseがPhase UP（図鑑拡張）可能か判定（獲得率80%以上でTRUE）
  Future<bool> canPhaseUp(int currentPhase) async {
    final phaseStamps = await database.getStampsByPhase(currentPhase);
    if (phaseStamps.isEmpty) return false;

    final unlockedCount = phaseStamps.where((s) => s.isUnlocked).length;
    final rate = unlockedCount / phaseStamps.length;
    return rate >= 0.8; // 80%以上 (16/20個以上)
  }

  /// 図鑑拡張（Phase UP）を実行し、次Phaseのスタンプ20個を追加
  Future<int> executePhaseUp() async {
    final currentMaxPhase = await database.getMaxStampPhase();
    final nextPhase = currentMaxPhase + 1;
    await generateAndInsertPhaseStamps(nextPhase);
    return nextPhase;
  }

  /// Phase別スタンプ定義の生成（1Phaseあたり20個）
  List<StampsCompanion> _buildStampsForPhase(int phase) {
    final List<StampsCompanion> list = [];

    if (phase == 1) {
      // --- Phase 1: 基礎学習・習慣化フェーズ (計20個) ---
      // Normal (14個)
      list.add(const StampsCompanion(
        id: Value('stamp_p1_01'),
        phase: Value(1),
        name: Value('ひよこの一歩'),
        rarity: Value('normal'),
        colorPaletteId: Value(7), // サニーレモン
        patternId: Value(0),      // ヒヨコ
        frameId: Value(0),        // 丸枠
        effectId: Value(0),
        conditionType: Value('none'),
        conditionValue: Value(0),
        description: Value('英語学習の旅路をスタートした証'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_02'),
        phase: Value(1),
        name: Value('気まぐれ子猫'),
        rarity: Value('normal'),
        colorPaletteId: Value(1), // サクラピンク
        patternId: Value(1),      // ネコ
        frameId: Value(1),        // 角丸四角
        effectId: Value(0),
        conditionType: Value('streak_days'),
        conditionValue: Value(2),
        description: Value('2日連続で学習を達成する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_03'),
        phase: Value(1),
        name: Value('忠実なワンコ'),
        rarity: Value('normal'),
        colorPaletteId: Value(6), // カフェモカ
        patternId: Value(2),      // イヌ
        frameId: Value(0),        // 丸枠
        effectId: Value(0),
        conditionType: Value('total_days'),
        conditionValue: Value(3),
        description: Value('累計3日間学習を継続する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_04'),
        phase: Value(1),
        name: Value('はじまりの双葉'),
        rarity: Value('normal'),
        colorPaletteId: Value(5), // フォレストハーブ
        patternId: Value(15),     // 双葉
        frameId: Value(1),        // 角丸四角
        effectId: Value(0),
        conditionType: Value('memorized_count'),
        conditionValue: Value(5),
        description: Value('英単語を累計5単語暗記する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_05'),
        phase: Value(1),
        name: Value('真っ赤なリンゴ'),
        rarity: Value('normal'),
        colorPaletteId: Value(2), // アンバー
        patternId: Value(14),     // リンゴ
        frameId: Value(0),        // 丸枠
        effectId: Value(0),
        conditionType: Value('cleared_chapters'),
        conditionValue: Value(1),
        description: Value('いずれかのチャプターを1つクリアする'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_06'),
        phase: Value(1),
        name: Value('朝の目覚まし時計'),
        rarity: Value('normal'),
        colorPaletteId: Value(3), // オーシャンスカイ
        patternId: Value(13),     // 時計
        frameId: Value(1),        // 角丸四角
        effectId: Value(0),
        conditionType: Value('total_days'),
        conditionValue: Value(5),
        description: Value('累計5日間学習を継続する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_07'),
        phase: Value(1),
        name: Value('学びの本と鉛筆'),
        rarity: Value('normal'),
        colorPaletteId: Value(0), // エメラルドミント
        patternId: Value(7),      // 開いた本
        frameId: Value(0),        // 丸枠
        effectId: Value(0),
        conditionType: Value('memorized_count'),
        conditionValue: Value(15),
        description: Value('英単語を累計15単語暗記する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_08'),
        phase: Value(1),
        name: Value('ひらめき電球'),
        rarity: Value('normal'),
        colorPaletteId: Value(7), // サニーレモン
        patternId: Value(12),     // 電球
        frameId: Value(1),        // 角丸四角
        effectId: Value(0),
        conditionType: Value('streak_days'),
        conditionValue: Value(3),
        description: Value('3日連続で学習を達成する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_09'),
        phase: Value(1),
        name: Value('小さな勇気の炎'),
        rarity: Value('normal'),
        colorPaletteId: Value(2), // アンバー
        patternId: Value(16),     // 炎
        frameId: Value(0),        // 丸枠
        effectId: Value(0),
        conditionType: Value('memorized_count'),
        conditionValue: Value(25),
        description: Value('英単語を累計25単語暗記する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_10'),
        phase: Value(1),
        name: Value('ほのぼのウサギ'),
        rarity: Value('normal'),
        colorPaletteId: Value(1), // サクラピンク
        patternId: Value(5),      // ウサギ
        frameId: Value(1),        // 角丸四角
        effectId: Value(0),
        conditionType: Value('total_days'),
        conditionValue: Value(7),
        description: Value('累計7日間学習を継続する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_11'),
        phase: Value(1),
        name: Value('よちよちペンギン'),
        rarity: Value('normal'),
        colorPaletteId: Value(3), // オーシャン
        patternId: Value(6),      // ペンギン
        frameId: Value(0),        // 丸枠
        effectId: Value(0),
        conditionType: Value('cleared_chapters'),
        conditionValue: Value(2),
        description: Value('チャプターを累計2つクリアする'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_12'),
        phase: Value(1),
        name: Value('やすらぎのハート'),
        rarity: Value('normal'),
        colorPaletteId: Value(4), // ラベンダー
        patternId: Value(11),     // ハート
        frameId: Value(1),        // 角丸四角
        effectId: Value(0),
        conditionType: Value('streak_days'),
        conditionValue: Value(4),
        description: Value('4日連続で学習を達成する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_13'),
        phase: Value(1),
        name: Value('幸運の四つ葉'),
        rarity: Value('normal'),
        colorPaletteId: Value(5), // フォレストハーブ
        patternId: Value(18),     // クローバー
        frameId: Value(0),        // 丸枠
        effectId: Value(0),
        conditionType: Value('memorized_count'),
        conditionValue: Value(35),
        description: Value('英単語を累計35単語暗記する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_14'),
        phase: Value(1),
        name: Value('知恵の小鍵'),
        rarity: Value('normal'),
        colorPaletteId: Value(0), // エメラルド
        patternId: Value(23),     // 鍵
        frameId: Value(1),        // 角丸四角
        effectId: Value(0),
        conditionType: Value('cleared_chapters'),
        conditionValue: Value(3),
        description: Value('チャプターを累計3つクリアする'),
      ));

      // Rare (4個)
      list.add(const StampsCompanion(
        id: Value('stamp_p1_15'),
        phase: Value(1),
        name: Value('知恵のフクロウ博士'),
        rarity: Value('rare'),
        colorPaletteId: Value(8), // ベリーバイオレット
        patternId: Value(3),      // フクロウ
        frameId: Value(2),        // 切手ギザギザ
        effectId: Value(1),       // 星粒子
        conditionType: Value('streak_days'),
        conditionValue: Value(5),
        description: Value('5日連続で学習を達成する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_16'),
        phase: Value(1),
        name: Value('努力のシルバーメダル'),
        rarity: Value('rare'),
        colorPaletteId: Value(9), // ロイヤルサファイア
        patternId: Value(9),      // トロフィー
        frameId: Value(3),        // 二重線枠
        effectId: Value(2),       // 集中線
        conditionType: Value('memorized_count'),
        conditionValue: Value(50),
        description: Value('英単語を累計50単語暗記する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_17'),
        phase: Value(1),
        name: Value('きらめく一番星'),
        rarity: Value('rare'),
        colorPaletteId: Value(11), // ゴールデンヴィンテージ
        patternId: Value(10),      // 星
        frameId: Value(2),         // 切手ギザギザ
        effectId: Value(1),        // 星粒子
        conditionType: Value('total_days'),
        conditionValue: Value(10),
        description: Value('累計10日間学習を継続する'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_18'),
        phase: Value(1),
        name: Value('百獣の若き獅子'),
        rarity: Value('rare'),
        colorPaletteId: Value(10), // クリムゾンルビー
        patternId: Value(4),       // ライオン
        frameId: Value(3),         // 二重線枠
        effectId: Value(4),        // 月桂樹
        conditionType: Value('cleared_chapters'),
        conditionValue: Value(5),
        description: Value('チャプターを累計5つクリアする'),
      ));

      // Super Rare (2個)
      list.add(const StampsCompanion(
        id: Value('stamp_p1_19'),
        phase: Value(1),
        name: Value('栄光のゴールドクラウン'),
        rarity: Value('super_rare'),
        colorPaletteId: Value(13), // マジェスティックゴールド
        patternId: Value(8),       // 王冠
        frameId: Value(4),         // 王冠エンブレム枠
        effectId: Value(3),        // 大星+シャイン
        conditionType: Value('streak_days'),
        conditionValue: Value(7),
        description: Value('7日連続（1週間連続）で学習を達成する！'),
      ));

      list.add(const StampsCompanion(
        id: Value('stamp_p1_20'),
        phase: Value(1),
        name: Value('輝きのダイヤモンド'),
        rarity: Value('super_rare'),
        colorPaletteId: Value(12), // ホログラフィックプリズム
        patternId: Value(17),      // ダイヤ
        frameId: Value(5),         // 太陽光線枠
        effectId: Value(3),        // 大星+シャイン
        conditionType: Value('memorized_count'),
        conditionValue: Value(100),
        description: Value('英単語を累計100単語暗記達成する！'),
      ));
    } else {
      // --- Phase 2以降: 拡張・高難度フェーズ ---
      final pPrefix = 'stamp_p${phase}_';
      final baseStreak = 7 + (phase - 1) * 7;
      final baseWords = 100 + (phase - 1) * 100;
      final baseDays = 14 + (phase - 1) * 14;
      final baseChaps = 5 + (phase - 1) * 5;

      final titles = [
        '静寂の知恵', '疾風の翼', '深緑の守護者', '黄昏の旅人', '暁のファンファーレ',
        '月下の読書家', '知性のコンパス', '不屈のチャレンジャー', '星屑の砂時計', '真紅の情熱',
        '純白の羽ペン', '翡翠のオルゴール', '碧落の羅針盤', '水晶のひらめき',
        '銀河の開拓者', '黄金のトロフィー', '天空のペガサス', '賢者の古文書',
        '不滅のフェニックス', '神話のドラゴンクラウン'
      ];

      for (int i = 0; i < 20; i++) {
        final idStr = '$pPrefix${(i + 1).toString().padLeft(2, '0')}';
        final name = titles[i % titles.length];

        String rarity = 'normal';
        int frame = i % 2;
        int eff = 0;
        int palette = (i + phase * 3) % 16;
        int pattern = (i + phase * 5) % 24;
        String condType = 'none';
        int condVal = 0;
        String desc = '';

        if (i < 14) {
          // Normal
          rarity = 'normal';
          frame = i % 2;
          eff = 0;
          if (i % 4 == 0) {
            condType = 'streak_days';
            condVal = min(30, baseStreak + (i ~/ 4) * 2);
            desc = '$condVal日連続で学習を達成する';
          } else if (i % 4 == 1) {
            condType = 'memorized_count';
            condVal = baseWords + (i ~/ 4) * 30;
            desc = '英単語を累計$condVal単語暗記する';
          } else if (i % 4 == 2) {
            condType = 'total_days';
            condVal = min(60, baseDays + (i ~/ 4) * 3);
            desc = '累計$condVal日間学習を継続する';
          } else {
            condType = 'cleared_chapters';
            condVal = min(30, baseChaps + (i ~/ 4) * 2);
            desc = 'チャプターを累計$condVal章クリアする';
          }
        } else if (i < 18) {
          // Rare
          rarity = 'rare';
          frame = 2 + (i % 2);
          eff = 1 + (i % 2);
          palette = 8 + (i % 4);
          pattern = (i * 3) % 24;
          if (i % 2 == 0) {
            condType = 'streak_days';
            condVal = min(60, baseStreak + 7);
            desc = '$condVal日連続で学習を達成する';
          } else {
            condType = 'memorized_count';
            condVal = baseWords + 100;
            desc = '英単語を累計$condVal単語暗記する';
          }
        } else {
          // Super Rare
          rarity = 'super_rare';
          frame = 4 + (i % 2);
          eff = 3;
          palette = 12 + (i % 4);
          pattern = (19 + (i - 18)) % 24; // 鳳凰/宝箱/聖杯/彗星
          if (i == 18) {
            condType = 'streak_days';
            condVal = min(90, baseStreak + 14);
            desc = '$condVal日連続学習の偉業を達成する！';
          } else {
            condType = 'memorized_count';
            condVal = baseWords + 200;
            desc = '英単語を累計$condVal単語暗記達成する！';
          }
        }

        list.add(StampsCompanion(
          id: Value(idStr),
          phase: Value(phase),
          name: Value(name),
          rarity: Value(rarity),
          colorPaletteId: Value(palette),
          patternId: Value(pattern),
          frameId: Value(frame),
          effectId: Value(eff),
          conditionType: Value(condType),
          conditionValue: Value(condVal),
          description: Value(desc),
        ));
      }
    }

    return list;
  }
}
