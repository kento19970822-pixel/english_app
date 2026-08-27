// コード管理番号: VER-20260826-01
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ネイティブ・ナチュラル英語音声集中管理サービス
class TtsService {
  static final TtsService instance = TtsService._internal();
  factory TtsService() => instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String? _selectedVoiceName;

  String? get selectedVoiceName => _selectedVoiceName;
  bool get isInitialized => _isInitialized;

  /// 初期化：最適なネイティブ英語音声を自動検出してバインド
  Future<void> initialize() async {
    if (_isInitialized && _selectedVoiceName != null) return;

    try {
      await _flutterTts.setLanguage("en-US");
      // 学習に最適な聞き取りやすいネイティブスピード（0.48）
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      await _selectAndSetBestVoice();
    } catch (e) {
      debugPrint("TtsService Init Error: $e");
    } finally {
      _isInitialized = true;
    }
  }

  Future<void> _selectAndSetBestVoice() async {
    try {
      final dynamic rawVoices = await _flutterTts.getVoices;
      if (rawVoices is List && rawVoices.isNotEmpty) {
        final bestVoice = selectBestVoice(rawVoices);
        if (bestVoice != null) {
          await _flutterTts.setVoice({
            "name": bestVoice['name'] ?? '',
            "locale": bestVoice['locale'] ?? 'en-US',
          });
          _selectedVoiceName = bestVoice['name'];
          debugPrint(
            "🔊 TtsService: 最適なネイティブ英語音声を適用しました -> ${_selectedVoiceName ?? 'デフォルト'}",
          );
        }
      }
    } catch (e) {
      debugPrint("TtsService Voice Selection Error: $e");
    }
  }

  /// 利用可能な音声リストから最も高品質な英語音声を選出するスコアリングロジック
  static Map<String, String>? selectBestVoice(List<dynamic> voices) {
    if (voices.isEmpty) return null;

    Map<String, String>? bestVoice;
    int bestScore = -1;

    for (final rawVoice in voices) {
      if (rawVoice is! Map) continue;
      final name = (rawVoice['name'] ?? '').toString();
      final locale = (rawVoice['locale'] ?? '').toString();

      // 英語以外の言語（日本語等）は完全に除外
      final cleanLocale = locale.toLowerCase().replaceAll('_', '-');
      if (!cleanLocale.startsWith('en')) {
        continue;
      }

      int score = 0;

      // 1. ロケール優先度
      if (cleanLocale == 'en-us') {
        score += 40; // アメリカ英語を最優先
      } else if (cleanLocale == 'en-gb') {
        score += 30; // イギリス英語を第2優先
      } else if (cleanLocale.startsWith('en')) {
        score += 15;
      }

      final lowerName = name.toLowerCase();

      // 2. 高音質ニューラル / ナチュラル / 拡張キーワード
      if (lowerName.contains('neural') || lowerName.contains('natural')) {
        score += 100; // 最上位ニューラル音声 (Windows Cortana / Android Neural / Azure)
      }
      if (lowerName.contains('wavenet')) {
        score += 90; // Google Wavenet
      }
      if (lowerName.contains('premium') || lowerName.contains('enhanced')) {
        score += 80; // iOS / macOS 高音質拡張 (Enhanced / Premium)
      }
      if (lowerName.contains('siri')) {
        score += 70; // Apple Siri 音声
      }

      // 3. 定評のある高品質ネイティブスピーカー名（iOS / Windows / Android / Chrome）
      if (lowerName.contains('ava') ||
          lowerName.contains('samantha') ||
          lowerName.contains('allison') ||
          lowerName.contains('susan') ||
          lowerName.contains('karen') ||
          lowerName.contains('moira') ||
          lowerName.contains('tessa') ||
          lowerName.contains('daniel') ||
          lowerName.contains('oliver') ||
          lowerName.contains('stephanie') ||
          lowerName.contains('alex') ||
          lowerName.contains('jenny') ||
          lowerName.contains('aria') ||
          lowerName.contains('guy') ||
          lowerName.contains('steffan') ||
          lowerName.contains('sonia') ||
          lowerName.contains('ryan')) {
        score += 50;
      } else if (lowerName.contains('zira') ||
          lowerName.contains('george') ||
          lowerName.contains('hazel') ||
          lowerName.contains('david') ||
          lowerName.contains('mark')) {
        score += 20;
      }

      // 4. ネットワーク高音質 (Android network/online)
      if (lowerName.contains('network') || lowerName.contains('online')) {
        score += 25;
      }

      if (score > bestScore) {
        bestScore = score;
        bestVoice = {
          'name': name,
          'locale': locale.isNotEmpty ? locale : 'en-US',
        };
      }
    }

    return bestVoice;
  }

  int _lastSpeakTimestamp = 0;
  String _lastSpokenText = '';

  /// 単語・テキストの音声再生（デバウンス＆排他制御）
  Future<void> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // 100ms以内の同一単語連打はデバウンス（多重発話防止）
    if (cleanText == _lastSpokenText && (now - _lastSpeakTimestamp) < 120) {
      return;
    }
    _lastSpeakTimestamp = now;
    _lastSpokenText = cleanText;

    try {
      if (!_isInitialized || _selectedVoiceName == null) {
        await initialize();
      }
      // 再生中の音声を確実に停止
      await _flutterTts.stop();
      // 常に英語(en-US)を強制適用
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint("TtsService speak error: $e");
      _isInitialized = false;
    }
  }

  /// 音声再生の停止
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _lastSpokenText = '';
    } catch (e) {
      debugPrint("TtsService stop error: $e");
    }
  }
}
