// コード管理番号: VER-20260827-12
import 'package:flutter/foundation.dart';
import '../db/app_database.dart';

/// SRS (Spaced Repetition System / 間隔反復復習) サービス
/// エビングハウス忘却曲線 ＆ SuperMemo SM-2 モデルに基づく最適な復習スケジュール管理
class SrsService {
  static SrsService? _instance;
  static SrsService get instance => _instance ??= SrsService();

  /// 本日復習期日（Due Words）を迎えている単語数を取得
  Future<int> getDueWordsCount(AppDatabase database, {DateTime? now}) async {
    try {
      final dueWords = await database.getDueWords(now: now, limit: 1000);
      return dueWords.length;
    } catch (e) {
      debugPrint('getDueWordsCount error: ');
      return 0;
    }
  }

  /// 本日の復習セッション用単語リストを取得
  Future<List<Word>> getReviewSessionWords(AppDatabase database, {int limit = 20, DateTime? now}) async {
    try {
      return await database.getDueWords(now: now, limit: limit);
    } catch (e) {
      debugPrint('getReviewSessionWords error: ');
      return [];
    }
  }

  /// 復習結果を記録し、次回推奨復習日時と難易度係数を更新
  /// [qualityScore]:
  ///   0: 完全忘却 (Blackout)
  ///   1: 不正解・誤答 (Incorrect)
  ///   2: 正解・難しかった (Hard)
  ///   3: 正解・普通 (Good)
  ///   4: 正解・完璧/即答 (Easy)
  Future<UserWordProgress> recordReviewResult({
    required AppDatabase database,
    required int wordId,
    required int qualityScore,
    DateTime? now,
  }) async {
    return await database.updateSrsReviewResult(
      wordId: wordId,
      quality: qualityScore.clamp(0, 4),
      now: now,
    );
  }

  /// SuperMemo SM-2 難易度係数（Ease Factor）の計算
  static double calculateNewEaseFactor(double currentEase, int qualityScore) {
    final q5 = (qualityScore + 1).clamp(0, 5);
    final delta = 0.1 - (5 - q5) * (0.08 + (5 - q5) * 0.02);
    final newEase = currentEase + delta;
    return newEase.clamp(1.3, 3.5);
  }

  /// 次回までの復習間隔日数（Interval Days）の計算
  static int calculateNextInterval(int currentInterval, double easeFactor, int qualityScore) {
    if (qualityScore < 2) {
      return 1; // 忘却・不正解時は1日にリセット
    }
    if (currentInterval <= 0) return 1;
    if (currentInterval == 1) return 3;
    if (currentInterval == 3) return 7;
    return (currentInterval * easeFactor).round();
  }
}
