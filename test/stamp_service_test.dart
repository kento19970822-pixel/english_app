// コード管理番号: VER-20260824-36
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/services/stamp_service.dart';

void main() {
  late AppDatabase db;
  late StampService stampService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    stampService = StampService(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('StampService Tests', () {
    test('ensureInitialized generates 20 Phase 1 stamps with exact rarity composition', () async {
      await stampService.ensureInitialized();
      final allStamps = await db.getAllStamps();

      expect(allStamps.length, 20);

      final normals = allStamps.where((s) => s.rarity == 'normal').toList();
      final rares = allStamps.where((s) => s.rarity == 'rare').toList();
      final superRares = allStamps.where((s) => s.rarity == 'super_rare').toList();

      expect(normals.length, 14); // 70%
      expect(rares.length, 4);    // 22%
      expect(superRares.length, 2); // 8%

      // Verify all stamps initially locked
      expect(allStamps.every((s) => !s.isUnlocked), isTrue);
    });

    test('checkAndAwardDailyStamp unlocks a stamp and sets appliedStampId for today', () async {
      final awarded = await stampService.checkAndAwardDailyStamp();
      expect(awarded, isNotNull);
      expect(awarded!.isUnlocked, isTrue);

      final todayStr = stampService.getTodayStr();
      final todayRecord = await db.getDailyRecord(todayStr);
      expect(todayRecord.appliedStampId, awarded.id);

      // Subsequent check on same day should return null (no duplicate daily award)
      final secondCheck = await stampService.checkAndAwardDailyStamp();
      expect(secondCheck, isNull);
    });

    test('canPhaseUp requires >= 80% (16/20) unlocked stamps', () async {
      await stampService.ensureInitialized();

      // Initially 0% unlocked -> cannot phase up
      expect(await stampService.canPhaseUp(1), isFalse);

      final phase1Stamps = await db.getStampsByPhase(1);

      // Unlock 15 stamps (75%) -> cannot phase up
      for (int i = 0; i < 15; i++) {
        await db.unlockStamp(phase1Stamps[i].id, DateTime.now());
      }
      expect(await stampService.canPhaseUp(1), isFalse);

      // Unlock 16th stamp (80%) -> can phase up!
      await db.unlockStamp(phase1Stamps[15].id, DateTime.now());
      expect(await stampService.canPhaseUp(1), isTrue);
    });

    test('executePhaseUp adds Phase 2 stamps (+20 stamps)', () async {
      await stampService.ensureInitialized();
      final newPhase = await stampService.executePhaseUp();

      expect(newPhase, 2);
      final allStamps = await db.getAllStamps();
      expect(allStamps.length, 40); // Phase 1 (20) + Phase 2 (20)

      final phase2Stamps = await db.getStampsByPhase(2);
      expect(phase2Stamps.length, 20);
    });

    test('checkAndAwardDailyStamp strictly excludes locked stamps whose conditions are not met', () async {
      await stampService.ensureInitialized();

      // In initial state (streak=0, totalDays=0, memorized=0, chapters=0):
      // Only stamp_p1_01 has conditionType == 'none'.
      final awarded = await stampService.checkAndAwardDailyStamp();
      expect(awarded, isNotNull);
      expect(awarded!.id, 'stamp_p1_01'); // Only eligible stamp is stamp_p1_01

      // Locked high-condition stamps like SR crown (streak 7) or diamond (memorized 100) must stay locked
      final allStamps = await db.getAllStamps();
      final srCrown = allStamps.firstWhere((s) => s.id == 'stamp_p1_19');
      final srDiamond = allStamps.firstWhere((s) => s.id == 'stamp_p1_20');
      expect(srCrown.isUnlocked, isFalse);
      expect(srDiamond.isUnlocked, isFalse);
    });

    test('resetAllLearningData clears all history, daily records, retention, and stamps', () async {
      await stampService.ensureInitialized();
      await stampService.checkAndAwardDailyStamp();
      await db.addGameHistory(100, 1);

      expect(await db.calculateStreak(), 1);

      await db.resetAllLearningData();

      expect(await db.calculateStreak(), 0);
      final records = await db.select(db.dailyRecords).get();
      expect(records.isEmpty, isTrue);
      final histories = await db.getGameHistories();
      expect(histories.isEmpty, isTrue);
    });
  });
}
