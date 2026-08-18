// コード管理番号: VER-20260818-14
import 'dart:math';

/// 回答判定ゾーンの定義
enum AnswerZone {
  fast, // 上部 1/3 (+50pt)
  normal, // 中部 2/3 (+30pt)
  slow, // 下部 3/3 (+10pt)
  miss, // 誤答 / タイムオーバー (-50pt & 制限フラグ)
}

/// 定着度・忘却曲線・制限フラグ計算サービス (F-05)
class RetentionService {
  /// ゾーン判定に応じた加算・減算ポイントと演出テキストの取得
  /// dropProgress: 0.0(最上部) 〜 1.0(最下部)
  static Map<String, dynamic> calculateScoreAndRetention({
    required double dropProgress,
    required bool isCorrect,
  }) {
    if (!isCorrect) {
      return {
        'retentionDelta': -50,
        'setDailyLimit': true, // 誤答時は制限フラグ付与
        'feedbackText': '❌ Miss',
        'soundType': 'wrong',
        'zone': AnswerZone.miss,
      };
    }

    // 🟢 上部 1/3 ゾーン (Fast)
    if (dropProgress < 0.33) {
      return {
        'retentionDelta': 50,
        'setDailyLimit': false,
        'feedbackText': '💥 Great!!',
        'soundType': 'correct_fast',
        'zone': AnswerZone.fast,
      };
    }
    // 🔵 中部 2/3 ゾーン (Normal)
    else if (dropProgress < 0.66) {
      return {
        'retentionDelta': 30,
        'setDailyLimit': false,
        'feedbackText': '👍 Good!',
        'soundType': 'correct_normal',
        'zone': AnswerZone.normal,
      };
    }
    // 🟡 下部 3/3 ゾーン (Slow)
    else {
      return {
        'retentionDelta': 10,
        'setDailyLimit': false,
        'feedbackText': '👌 OK',
        'soundType': 'correct_slow',
        'zone': AnswerZone.slow,
      };
    }
  }

  /// クイズ回答後の定着度ポイント・暗記済み・制限フラグの計算
  static Map<String, dynamic> processQuizResult({
    required int currentPoint,
    required int delta,
    required bool isRestricted,
    required bool setDailyLimit,
  }) {
    int newPoint = currentPoint + delta;
    newPoint = newPoint.clamp(0, 100);

    bool newRestricted = isRestricted || setDailyLimit;

    // 制限フラグが有効な場合は当日の上限を70ptに抑える
    if (newRestricted && newPoint > 70) {
      newPoint = 70;
    }

    // 暗記済みフラグ判定: 80pt以上でON
    final bool newIsMemorized = newPoint >= 80;

    return {
      'retentionPoint': newPoint,
      'isMemorized': newIsMemorized,
      'isRestricted': newRestricted,
    };
  }

  /// 忘却曲線減算ロジック (エビングハウス忘却モデル)
  /// 次回定着度 = 現在の定着度 * (1 - (経過日数 / (経過日数 + 2 + (正解回数 * 2))))
  static int calculateForgettingCurve({
    required int currentPoint,
    required DateTime? lastStudiedAt,
    required int correctCount,
    DateTime? now,
  }) {
    if (lastStudiedAt == null || currentPoint <= 0) return currentPoint;

    final currentDate = now ?? DateTime.now();
    final deltaDays = currentDate.difference(lastStudiedAt).inDays;

    if (deltaDays <= 0) return currentPoint;

    final double denominator = deltaDays + 2.0 + (correctCount * 2.0);
    final double factor = 1.0 - (deltaDays / denominator);

    final double calculatedPoint = currentPoint * max(0.0, factor);
    return calculatedPoint.round().clamp(0, 100);
  }

  /// 日付更新判定（0:00跨ぎでの制限フラグ解除チェック）
  static bool shouldResetRestriction(
    DateTime? lastRestrictedDate, {
    DateTime? now,
  }) {
    if (lastRestrictedDate == null) return false;
    final currentDate = now ?? DateTime.now();

    final lastDateOnly = DateTime(
      lastRestrictedDate.year,
      lastRestrictedDate.month,
      lastRestrictedDate.day,
    );
    final currentDateOnly = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    return currentDateOnly.isAfter(lastDateOnly);
  }
}
