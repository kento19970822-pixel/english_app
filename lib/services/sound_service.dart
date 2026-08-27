// コード管理番号: VER-20260826-09
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 効果音（SE）集中管理サービス
class SoundService extends ChangeNotifier {
  static final SoundService instance = SoundService._internal();
  factory SoundService() => instance;
  SoundService._internal();

  AudioPlayer? _audioPlayer;
  bool _isSeEnabled = true;
  bool _isInitialized = false;

  bool get isSeEnabled => _isSeEnabled;

  AudioPlayer _getPlayer() {
    return _audioPlayer ??= AudioPlayer();
  }

  /// 初期化：設定の読み込みとオーディオプレイヤー準備
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSeEnabled = prefs.getBool('se_enabled') ?? true;
      try {
        final player = _getPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(1.0);

        // iOS: マナーモード（サイレントスイッチ）時に音を出さない ambient 設定
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: const {
                AVAudioSessionOptions.mixWithOthers,
              },
            ),
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: false,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.assistanceSonification,
              audioFocus: AndroidAudioFocus.none,
            ),
          ),
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('SoundService Init Error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 効果音のON / OFF切り替え
  Future<void> setSeEnabled(bool enabled) async {
    _isSeEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('se_enabled', enabled);
    } catch (e) {
      debugPrint('SoundService Save Error: $e');
    }
  }

  Future<void> _playAsset(String path) async {
    if (!_isSeEnabled) return;
    try {
      final player = _getPlayer();
      await player.stop();
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('SoundService play error: $e');
    }
  }

  /// 暗記完了音（右スワイプ / 80pt達成）
  Future<void> playMemorized() async {
    if (!_isSeEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    await _playAsset('sounds/correct.mp3');
  }

  /// リセット音（左スワイプ / 0ptリセット）
  Future<void> playReset() async {
    if (!_isSeEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
    await _playAsset('sounds/wrong.mp3');
  }

  /// お気に入り★登録音
  Future<void> playFavorite() async {
    if (!_isSeEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
    await _playAsset('sounds/correct.mp3');
  }

  /// 正解音（ゲーム用）
  Future<void> playCorrect() async {
    if (!_isSeEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
    await _playAsset('sounds/correct.mp3');
  }

  /// 不正解音（ゲーム用）
  Future<void> playWrong() async {
    if (!_isSeEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
    await _playAsset('sounds/wrong.mp3');
  }

  /// チャプタークリア・進化達成音
  Future<void> playFanfare() async {
    if (!_isSeEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
    await _playAsset('sounds/correct.mp3');
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}
