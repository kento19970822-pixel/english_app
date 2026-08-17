// コード管理番号: VER-20260817-123
import 'dart:math';

class RetentionService {
  /// ゾーン判定に応じた加算・減算ポイントと演出テキストの取得
  /// dropProgress: 0.0(最上部) 〜 1.0(最下部)
  static Map<String, dynamic> calculateScoreAndRetention({
    required double dropProgress,
    required bool isCorrect,
  }) {
    if (!isCorrect) {
      return {
        'retentionDelta': -30.0,
        'setDailyLimit': true,
        'feedbackText': '❌ Miss',
        'soundType': 'wrong',
      };
    }

    // 🟢 上部 1/3 ゾーン (Fast)
    if (dropProgress < 0.33) {
      return {
        'retentionDelta': 50.0,
        'setDailyLimit': false,
        'feedbackText': '💥 Great!!',
        'soundType': 'correct_fast',
      };
    }
    // 🔵 中部 2/3 ゾーン (Normal)
    else if (dropProgress < 0.66) {
      return {
        'retentionDelta': 30.0,
        'setDailyLimit': false,
        'feedbackText': '👍 Good!',
        'soundType': 'correct_normal',
      };
    }
    // 🟡 下部 3/3 ゾーン (Slow)
    else {
      return {
        'retentionDelta': 20.0,
        'setDailyLimit': true, // 当日上限 70pt 制限付与
        'feedbackText': '👌 OK',
        'soundType': 'correct_slow',
      };
    }
  }

  /// 次回定着度ポイントの計算
  static double calculateNextRetentionRate({
    required double currentRate,
    required double delta,
    required bool dailyLimitFlag,
  }) {
    final double maxLimit = dailyLimitFlag ? 70.0 : 100.0;
    final double newRate = currentRate + delta;
    return min(max(newRate, 0.0), maxLimit);
  }

  /// 忘却曲線減算ロジック (エビングハウス忘却モデル)
  /// 次回定着度 = 現在の定着度 * (1 - (経過日数 / (経過日数 + 2 + (正解回数 * 2))))
  static double calculateForgettingCurve({
    required double currentRate,
    required int deltaDays,
    required int correctCount,
  }) {
    if (deltaDays <= 0 || currentRate <= 0) return currentRate;

    final double factor =
        1.0 - (deltaDays / (deltaDays + 2.0 + (correctCount * 2.0)));
    return max(0.0, currentRate * factor);
  }
}
