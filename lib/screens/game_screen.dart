// コード管理番号: VER-20260826-01
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../db/app_database.dart';
import '../services/retention_service.dart';
import '../services/stamp_service.dart';
import '../services/tts_service.dart';
import '../widgets/stamp_reward_dialog.dart';

class WordModel {
  final int id;
  final String english;
  final String japanese;
  final int level;
  final int chapter;
  final int retentionPoint;
  final bool isMemorized;
  final bool isRestricted;
  bool isFavorite;
  final int correctCount;
  final int wrongCount;

  WordModel({
    required this.id,
    required this.english,
    required this.japanese,
    required this.level,
    required this.chapter,
    this.retentionPoint = 0,
    this.isMemorized = false,
    this.isRestricted = false,
    this.isFavorite = false,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  factory WordModel.fromDrift(Word driftWord) {
    int parsedLevel = 1;
    final cefr = driftWord.cefr.toUpperCase().trim();

    if (cefr.contains('A1') ||
        cefr.contains('A2') ||
        cefr == '1' ||
        cefr.contains('初級')) {
      parsedLevel = 1;
    } else if (cefr.contains('B1') ||
        cefr.contains('B2') ||
        cefr == '2' ||
        cefr.contains('中級')) {
      parsedLevel = 2;
    } else if (cefr.contains('C1') ||
        cefr.contains('C2') ||
        cefr == '3' ||
        cefr.contains('上級')) {
      parsedLevel = 3;
    } else {
      parsedLevel = 1;
    }

    return WordModel(
      id: driftWord.id,
      english: driftWord.english,
      japanese: driftWord.japanese,
      level: parsedLevel,
      chapter: driftWord.chapter,
      retentionPoint: driftWord.retentionPoint,
      isMemorized: driftWord.isMemorized,
      isRestricted: driftWord.isRestricted,
      isFavorite: driftWord.isFavorite,
      correctCount: driftWord.correctCount,
      wrongCount: driftWord.wrongCount,
    );
  }
}

class GameScreen extends StatefulWidget {
  final AppDatabase database;
  final Function(bool isStarted)? onGameStateChanged;
  final String mode; // 'challenge' or 'learning'
  final int initialLevel;
  final int initialChapter;
  final bool autoStart;

  const GameScreen({
    super.key,
    required this.database,
    this.onGameStateChanged,
    this.mode = 'challenge',
    this.initialLevel = 1,
    this.initialChapter = 1,
    this.autoStart = true,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final double totalGameDuration = 60.0;
  final int dropDurationSeconds = 8;

  double remainingTime = 60.0;
  int score = 0;
  int combo = 0;
  bool isGameStarted = false;
  bool isGameOver = false;
  bool isPaused = false;
  bool isLoading = true;

  late int selectedLevel;
  late int selectedChapter;
  late String currentMode;

  Timer? gameTimer;
  late AudioPlayer _seAudioPlayer;

  List<WordModel> allWords = [];
  List<WordModel> questionQueue = [];
  List<WordModel> mistakenWords = [];
  Set<int> favoriteWordIds = {};

  // F-05: 1ゲーム1変動原則（セッション中に既にDB反映・ポイント評価を行った単語IDを記録）
  final Set<int> _processedWordIds = {};
  int _correctCount = 0;
  int _totalAnsweredCount = 0;

  WordModel? leftWord;
  List<String> leftChoices = [];
  Set<String> leftDisabledChoices = {};
  late AnimationController _leftDropController;
  DateTime? _leftQuestionStartTime;
  bool isLeftStarted = false;
  bool leftMistaken = false;
  String? leftFeedback;

  WordModel? rightWord;
  List<String> rightChoices = [];
  Set<String> rightDisabledChoices = {};
  late AnimationController _rightDropController;
  DateTime? _rightQuestionStartTime;
  bool rightMistaken = false;
  String? rightFeedback;

  Timer? _leftStartTimer;

  // カウントダウン演出用
  late AnimationController _countdownAnimController;
  late Animation<double> _countdownScaleAnimation;
  late Animation<double> _countdownOpacityAnimation;
  String? _countdownText;
  int _countdownSessionId = 0;

  @override
  void initState() {
    super.initState();
    selectedLevel = widget.initialLevel;
    selectedChapter = widget.initialChapter;
    currentMode = widget.mode;

    _seAudioPlayer = AudioPlayer();
    _initTts();

    _countdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _countdownScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _countdownAnimController,
        curve: Curves.elasticOut,
      ),
    );
    _countdownOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _countdownAnimController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _leftDropController = AnimationController(
      vsync: this,
      duration: Duration(seconds: dropDurationSeconds),
    );
    _leftDropController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleTimeOut(isLeft: true);
      }
    });

    _rightDropController = AnimationController(
      vsync: this,
      duration: Duration(seconds: dropDurationSeconds),
    );
    _rightDropController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleTimeOut(isLeft: false);
      }
    });

    _loadWordsFromDb().then((_) {
      if (mounted) {
        _startCountdownSequence();
      }
    });
  }

  Future<void> _loadWordsFromDb() async {
    final dbWords = await widget.database.getAllWords();
    setState(() {
      allWords = dbWords
          .map((w) => WordModel.fromDrift(w))
          .where((w) => w.english.trim().isNotEmpty && w.japanese.trim().isNotEmpty)
          .toList();
      favoriteWordIds = dbWords
          .where((w) => w.isFavorite == true)
          .map((w) => w.id)
          .toSet();
      isLoading = false;
    });
  }

  Future<void> _initTts() async {
    await TtsService.instance.initialize();
  }

  Future<void> _playAudio(WordModel word) async {
    await TtsService.instance.speak(word.english);
  }

  void _playSE(String type) async {
    try {
      String fileName = "";
      if (type == 'correct' || type.startsWith('correct_')) {
        fileName = "sounds/correct.mp3";
      } else if (type == 'wrong' || type == 'timeout') {
        fileName = "sounds/wrong.mp3";
      }

      if (fileName.isNotEmpty) {
        try {
          await _seAudioPlayer.stop();
        } catch (_) {}
        await _seAudioPlayer.play(AssetSource(fileName));
      }
    } catch (e) {
      debugPrint("SE Play Error: $e");
    }
  }

  void _recordMistake(WordModel word) {
    if (!mistakenWords.any((w) => w.id == word.id)) {
      mistakenWords.add(word);
    }
  }

  void _resetAndStopAll() {
    _countdownSessionId++;
    _countdownAnimController.stop();
    _countdownAnimController.reset();
    _countdownText = null;

    gameTimer?.cancel();
    gameTimer = null;
    _leftStartTimer?.cancel();
    _leftStartTimer = null;

    _leftQuestionStartTime = null;
    _rightQuestionStartTime = null;

    _leftDropController.stop();
    _leftDropController.reset();
    _rightDropController.stop();
    _rightDropController.reset();
  }

  void _startCountdownSequence({List<WordModel>? customWords}) async {
    _resetAndStopAll();

    List<WordModel> targetWords = [];
    if (customWords != null && customWords.isNotEmpty) {
      targetWords = List.from(customWords);
    } else if (currentMode == 'learning') {
      // 1. 学習モード: 選択チャプター（selectedChapter）の全単語を抽出
      targetWords = allWords
          .where((w) => w.chapter == selectedChapter)
          .toList();

      // 単語数が極端に少ない場合の安全なフォールバック（同レベルから補充）
      if (targetWords.length < 5) {
        final sameLevel = allWords.where((w) => w.level == selectedLevel).toList();
        targetWords = sameLevel.isNotEmpty ? sameLevel : List.from(allWords);
      }

      // 未暗記（80pt未満 / isMemorized == false）の単語を優先して前方に配置し、全単語を学習可能に
      final unmemorized = targetWords.where((w) => !w.isMemorized).toList()..shuffle();
      final memorized = targetWords.where((w) => w.isMemorized).toList()..shuffle();
      targetWords = [...unmemorized, ...memorized];
    } else if (currentMode == 'weakness') {
      // 2. 弱点克服モード: 誤答・低定着・未暗記の単語を苦手スコア順に抽出
      final filtered = allWords.where((w) => w.level == selectedLevel).toList();
      final pool = filtered.isNotEmpty ? filtered : List<WordModel>.from(allWords);
      final List<MapEntry<WordModel, int>> scored = pool.map<MapEntry<WordModel, int>>((WordModel w) {
        int weaknessScore = (w.wrongCount * 3);
        if (!w.isMemorized) weaknessScore += 10;
        if (w.retentionPoint < 50) weaknessScore += 10;
        weaknessScore -= w.correctCount.toInt();
        return MapEntry<WordModel, int>(w, weaknessScore);
      }).toList();
      scored.sort((a, b) => b.value.compareTo(a.value));
      targetWords = scored.map<WordModel>((e) => e.key).take(100).toList();
    } else {
      // 3. チャレンジモード: 選択中レベルの全単語をシャッフル
      targetWords = allWords.where((w) => w.level == selectedLevel).toList();
      if (targetWords.length < 5) {
        targetWords = List.from(allWords);
      }
      targetWords.shuffle();
    }

    if (targetWords.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('単語データが取得できませんでした。')));
      }
      return;
    }

    final currentSession = ++_countdownSessionId;

    setState(() {
      _isEnding = false;
      isGameStarted = true;
      remainingTime = totalGameDuration;
      score = 0;
      combo = 0;
      _correctCount = 0;
      _totalAnsweredCount = 0;
      isGameOver = false;
      isPaused = false;
      isLeftStarted = false;
      questionQueue = List.from(targetWords);
      mistakenWords.clear();
      _processedWordIds.clear(); // F-05: 1ゲーム1変動フラグを初期化

      leftWord = null;
      rightWord = null;
      leftChoices = [];
      rightChoices = [];
      leftDisabledChoices.clear();
      rightDisabledChoices.clear();
      leftFeedback = null;
      rightFeedback = null;
    });

    widget.onGameStateChanged?.call(true);

    // 画面遷移アニメーション完了を待ってからカウントダウンを開始
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _countdownSessionId != currentSession || !isGameStarted || isGameOver) return;

    final steps = ['3', '2', '1', 'スタート!'];
    for (int i = 0; i < steps.length; i++) {
      if (!mounted || _countdownSessionId != currentSession || !isGameStarted || isGameOver) return;
      setState(() {
        _countdownText = steps[i];
      });
      _countdownAnimController.forward(from: 0.0);
      if (steps[i] == 'スタート!') {
        _playSE('correct');
        await Future.delayed(const Duration(milliseconds: 700));
      } else {
        await Future.delayed(const Duration(milliseconds: 850));
      }
    }

    if (!mounted || _countdownSessionId != currentSession || !isGameStarted || isGameOver) return;

    setState(() {
      _countdownText = null;
    });

    _startGameActual();
  }

  void _startGameActual() {
    if (!mounted || !isGameStarted || isGameOver || isPaused) return;

    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isPaused || isGameOver) return;
      if (remainingTime > 0.1) {
        setState(() {
          remainingTime -= 0.1;
        });
      } else {
        timer.cancel();
        gameTimer = null;
        setState(() {
          remainingTime = 0.0;
        });
        _endGame();
      }
    });

    _nextQuestion(isLeft: false);

    _leftStartTimer = Timer(const Duration(seconds: 2), () {
      _triggerLeftStart();
    });
  }

  void _triggerLeftStart() {
    if (!isLeftStarted && !isGameOver && !isPaused && isGameStarted) {
      isLeftStarted = true;
      _leftStartTimer?.cancel();
      _nextQuestion(isLeft: true);
    }
  }

  List<String> _generateChoices(WordModel correctWord) {
    final correctJapanese = correctWord.japanese.trim();

    // 1. 全単語から空文字・正解と重複しないユニークな日本語訳候補を抽出
    final uniqueCandidateMeanings = allWords
        .map((w) => w.japanese.trim())
        .where((j) => j.isNotEmpty && j != correctJapanese)
        .toSet()
        .toList();
    uniqueCandidateMeanings.shuffle();

    // 2. 誤答候補を必ず3つ取得
    final wrongChoices = uniqueCandidateMeanings.take(3).toList();

    // 3. 万が一候補が3つに満たない場合の安全なフォールバック
    const fallbackList = [
      '走る', '話す', '歩く', '食べる', '本', '水', '空', '時間', '友達', '家', '学校', '音楽'
    ];
    for (final fb in fallbackList) {
      if (wrongChoices.length >= 3) break;
      if (fb != correctJapanese && !wrongChoices.contains(fb)) {
        wrongChoices.add(fb);
      }
    }

    // 4. 正解を含めて4つの選択肢をシャッフル
    final choices = [...wrongChoices, correctJapanese]..shuffle();
    return choices;
  }

  void _nextQuestion({required bool isLeft}) {
    if (questionQueue.isEmpty || isGameOver || !isGameStarted) {
      if (leftWord == null && rightWord == null) {
        _endGame();
      }
      return;
    }

    final nextWord = questionQueue.removeAt(0);
    final choices = _generateChoices(nextWord);

    setState(() {
      if (isLeft) {
        leftWord = nextWord;
        leftChoices = choices;
        leftDisabledChoices.clear();
        leftMistaken = false;
        leftFeedback = null;
      } else {
        rightWord = nextWord;
        rightChoices = choices;
        rightDisabledChoices.clear();
        rightMistaken = false;
        rightFeedback = null;
      }
    });

    _playAudio(nextWord);

    final now = DateTime.now();
    if (isLeft) {
      _leftQuestionStartTime = now;
      _leftDropController.reset();
      _leftDropController.forward();
    } else {
      _rightQuestionStartTime = now;
      _rightDropController.reset();
      _rightDropController.forward();
    }
  }

  void _handleAnswer({required bool isLeft, required String selectedChoice}) {
    final targetWord = isLeft ? leftWord : rightWord;
    final controller = isLeft ? _leftDropController : _rightDropController;

    if (targetWord == null || isPaused || !isGameStarted) return;

    if (selectedChoice == targetWord.japanese) {
      // 端末/ブラウザのTicker跳躍に左右されない実経過時間ベースの正確な進捗計算
      final startTime = isLeft ? _leftQuestionStartTime : _rightQuestionStartTime;
      double progress = controller.value;
      if (startTime != null) {
        final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        final realProgress = (elapsedMs / (dropDurationSeconds * 1000.0)).clamp(0.0, 1.0);
        progress = realProgress;
      }

      final result = RetentionService.calculateScoreAndRetention(
        dropProgress: progress,
        isCorrect: true,
      );

      controller.stop();
      _playSE(result['soundType'] as String);

      // F-05: 1ゲーム1変動原則に基づき、初回回答時のみDBの定着度を更新
      if (!_processedWordIds.contains(targetWord.id)) {
        _processedWordIds.add(targetWord.id);
        widget.database.updateWordQuizResult(
          id: targetWord.id,
          dropProgress: progress,
          isCorrect: true,
        );
      }

      // 画面上の加点および演出
      final int baseDelta = result['retentionDelta'] as int;
      final addScore = baseDelta + (combo * 2);

      setState(() {
        score += addScore;
        combo += 1;
        _correctCount += 1;
        _totalAnsweredCount += 1;
        final fb = "${result['feedbackText']} (+$addScore)";
        if (isLeft) {
          leftFeedback = fb;
        } else {
          rightFeedback = fb;
        }
      });

      if (!isLeft && !isLeftStarted) {
        _triggerLeftStart();
      }

      final wasMistaken = isLeft ? leftMistaken : rightMistaken;
      if (wasMistaken) {
        questionQueue.add(targetWord);
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || isGameOver || !isGameStarted) return;
        setState(() {
          if (isLeft) {
            leftWord = null;
            leftChoices = [];
          } else {
            rightWord = null;
            rightChoices = [];
          }
        });
        _nextQuestion(isLeft: isLeft);
      });
    } else {
      final startTime = isLeft ? _leftQuestionStartTime : _rightQuestionStartTime;
      double progress = controller.value;
      if (startTime != null) {
        final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        progress = (elapsedMs / (dropDurationSeconds * 1000.0)).clamp(0.0, 1.0);
      }

      final result = RetentionService.calculateScoreAndRetention(
        dropProgress: progress,
        isCorrect: false,
      );

      _playSE(result['soundType'] as String);
      _recordMistake(targetWord);

      // F-05: 1ゲーム1変動原則に基づき、初回回答時のみDBの定着度・制限フラグ等を更新
      if (!_processedWordIds.contains(targetWord.id)) {
        _processedWordIds.add(targetWord.id);
        widget.database.updateWordQuizResult(
          id: targetWord.id,
          dropProgress: progress,
          isCorrect: false,
        );
      }

      setState(() {
        combo = 0;
        _totalAnsweredCount += 1;
        if (isLeft) {
          leftDisabledChoices.add(selectedChoice);
          leftMistaken = true;
          leftFeedback = result['feedbackText'] as String;
        } else {
          rightDisabledChoices.add(selectedChoice);
          rightMistaken = true;
          rightFeedback = result['feedbackText'] as String;
        }
      });
    }
  }

  void _handleTimeOut({required bool isLeft}) {
    if (!isGameStarted || isGameOver || isPaused) return;
    final targetWord = isLeft ? leftWord : rightWord;
    if (targetWord == null) return;

    // Safari等のTicker跳躍/誤完了ガード（落下開始から実時間で最低40%以上経過していない異常トリガーは無視して復元）
    final startTime = isLeft ? _leftQuestionStartTime : _rightQuestionStartTime;
    if (startTime != null) {
      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsedMs < (dropDurationSeconds * 1000 * 0.4).toInt()) {
        final controller = isLeft ? _leftDropController : _rightDropController;
        final correctProgress = (elapsedMs / (dropDurationSeconds * 1000.0)).clamp(0.0, 1.0);
        controller.value = correctProgress;
        controller.forward();
        return;
      }
    }

    _playSE('timeout');
    _recordMistake(targetWord);

    // F-05: タイムオーバー時も初回であれば誤答扱いとしてDB更新（制限フラグ付与等）
    if (!_processedWordIds.contains(targetWord.id)) {
      _processedWordIds.add(targetWord.id);
      widget.database.updateWordQuizResult(
        id: targetWord.id,
        dropProgress: 1.0,
        isCorrect: false,
      );
    }

    setState(() {
      combo = 0;
      _totalAnsweredCount += 1;
      if (isLeft) {
        leftFeedback = "タイムオーバー!";
      } else {
        rightFeedback = "タイムオーバー!";
      }
    });

    questionQueue.add(targetWord);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || isGameOver || !isGameStarted) return;
      setState(() {
        if (isLeft) {
          leftWord = null;
          leftChoices = [];
        } else {
          rightWord = null;
          rightChoices = [];
        }
      });
      _nextQuestion(isLeft: isLeft);
    });
  }

  void _togglePause() {
    if (isGameOver || !isGameStarted) return;
    setState(() {
      isPaused = !isPaused;
    });

    if (isPaused) {
      _leftDropController.stop();
      _rightDropController.stop();
      _showPauseDialog();
    } else {
      if (leftWord != null && !isGameOver) _leftDropController.forward();
      if (rightWord != null && !isGameOver) _rightDropController.forward();
    }
  }

  void _showPauseDialog() {
    if (isGameOver || !isGameStarted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5DEC9)),
        ),
        title: const Text(
          '一時停止中',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C302E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ゲームが一時停止しています。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B726E)),
            ),
            const SizedBox(height: 20),
            // 再開するボタン（中央揃え）
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text(
                  'ゲームを再開する',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F9E98),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _togglePause();
                },
              ),
            ),
            const SizedBox(height: 10),
            // リスタートボタン（中央揃え・最初からやり直す）
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  '最初からやり直す',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5F9E98),
                  side: const BorderSide(color: Color(0xFF5F9E98), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _startCountdownSequence();
                },
              ),
            ),
            const SizedBox(height: 10),
            // 中止するボタン（中央揃え）
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  'ゲームを中止する',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _cancelGame();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelGame() {
    _resetAndStopAll();
    widget.onGameStateChanged?.call(false);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Map<String, dynamic>? _unlockResult;
  bool _isEnding = false;

  void _endGame() async {
    if (_isEnding || isGameOver) return;
    _isEnding = true;
    _resetAndStopAll();

    // 即座にリザルト画面状態へ遷移（ポーズボタンや落下処理の即時停止）
    if (mounted) {
      setState(() {
        remainingTime = 0.0;
        isGameOver = true;
        isPaused = false;
        isGameStarted = false;
      });
    }

    // F-10: 本日のプレイ回数加算と学習履歴の保存
    try {
      await widget.database.addGameHistory(score, selectedLevel);
    } catch (e) {
      debugPrint("addGameHistory error: $e");
    }

    // F-15: 学習モードの場合、チャプター暗記率判定および次チャプター解放処理を実行
    Map<String, dynamic>? unlockResult;
    try {
      if (currentMode == 'learning') {
        unlockResult = await widget.database.checkAndUnlockNextChapter(selectedChapter);
      }
    } catch (e) {
      debugPrint("checkAndUnlockNextChapter error: $e");
    }

    // F-11/F-12: 当日初回クリア時のスタンプ判定 & 獲得演出
    Stamp? awardedStamp;
    try {
      final stampService = StampService(database: widget.database);
      awardedStamp = await stampService.checkAndAwardDailyStamp();
    } catch (e) {
      debugPrint("Daily Stamp Award Error: $e");
    }

    if (mounted) {
      setState(() {
        _unlockResult = unlockResult;
      });

      if (awardedStamp != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && isGameOver) {
            StampRewardDialog.show(context, awardedStamp!, widget.database);
          }
        });
      }
    }
  }

  Future<void> _toggleFavorite(WordModel word) async {
    final isFav = favoriteWordIds.contains(word.id);
    final nextFav = !isFav;

    await widget.database.toggleFavorite(word.id, nextFav);

    setState(() {
      if (nextFav) {
        favoriteWordIds.add(word.id);
      } else {
        favoriteWordIds.remove(word.id);
      }
      word.isFavorite = nextFav;
    });
  }

  @override
  void dispose() {
    _resetAndStopAll();
    _countdownAnimController.dispose();
    _leftDropController.dispose();
    _rightDropController.dispose();
    _seAudioPlayer.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5F9E98))));
    }

    final modeTitle = currentMode == 'learning'
        ? '学習モード (Ch.$selectedChapter)'
        : (currentMode == 'weakness' ? '弱点克服モード' : 'チャレンジモード');

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onGameStateChanged?.call(false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 40,
          title: Text(
            modeTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C302E),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (isGameStarted && !isGameOver && _countdownText == null)
              IconButton(
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 22,
                  color: const Color(0xFF5F9E98),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: _togglePause,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5DEC9), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // 残り時間: 左端
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '残り時間: ${isGameOver ? '0s' : '${max(0.0, remainingTime).toStringAsFixed(1)}s'}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: (isGameOver || remainingTime <= 10)
                                  ? Colors.red
                                  : const Color(0xFF2C302E),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // コンボ: 中央
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: combo > 1
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$combo COMBO!',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFECA882),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    // スコア: 右端
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'スコア: $score',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5F9E98),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isGameOver
                    ? _buildResultScreen()
                    : Stack(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildLane(
                                  isLeft: true,
                                  word: leftWord,
                                  choices: leftChoices,
                                  disabledChoices: leftDisabledChoices,
                                  controller: _leftDropController,
                                  feedback: leftFeedback,
                                  laneColor: Colors.blue.shade50,
                                  cardColor: const Color(0xFF4A90E2),
                                ),
                              ),
                              const VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: Color(0xFFD0D7DE),
                              ),
                              Expanded(
                                child: _buildLane(
                                  isLeft: false,
                                  word: rightWord,
                                  choices: rightChoices,
                                  disabledChoices: rightDisabledChoices,
                                  controller: _rightDropController,
                                  feedback: rightFeedback,
                                  laneColor: Colors.indigo.shade50,
                                  cardColor: const Color(0xFF5C6BC0),
                                ),
                              ),
                            ],
                          ),
                          if (_countdownText != null)
                            _buildCountdownOverlay(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    final isStart = _countdownText == 'スタート!';

    return Container(
      color: const Color(0xFFFBF7EE).withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _countdownAnimController,
        builder: (context, child) {
          return Opacity(
            opacity: _countdownOpacityAnimation.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _countdownScaleAnimation.value,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isStart ? 32 : 28,
                  vertical: isStart ? 16 : 22,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.circular(isStart ? 24 : 50),
                  border: Border.all(
                    color: isStart ? const Color(0xFFECA882) : const Color(0xFF5F9E98),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isStart ? const Color(0xFFECA882) : const Color(0xFF5F9E98))
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _countdownText ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isStart ? 32 : 56,
                      fontWeight: FontWeight.w900,
                      color: isStart ? const Color(0xFFECA882) : const Color(0xFF5F9E98),
                      letterSpacing: isStart ? 2.0 : 0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultScreen() {
    final isLearning = currentMode == 'learning';
    final rate = (_unlockResult?['memorizedRate'] as double?) ?? 0.0;
    final isCleared = (_unlockResult?['isCleared'] as bool?) ?? false;
    final nextChapter = _unlockResult?['nextChapterUnlocked'] as int?;
    final isNewUnlock = (_unlockResult?['isNewUnlock'] as bool?) ?? false;

    return Container(
      color: const Color(0xFFFBF7EE),
      child: Column(
        children: [
          // スクロール可能なリザルトカード ＆ 要復習単語リスト
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 1,
                    color: const Color(0xFFFFFDF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE5DEC9)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ゲーム終了！',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C302E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '最終スコア: $score',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF5F9E98),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 正解単語数・ミス単語数・正答率サマリーチップ (F-03/F-07)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFA5D6A7)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('正解単語数', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('$_correctCount 語', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEF9A9A)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('ミス単語数', style: TextStyle(fontSize: 10, color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('${mistakenWords.length} 語', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF90CAF9)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('正答率', style: TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_totalAnsweredCount > 0 ? ((_correctCount / _totalAnsweredCount) * 100).toInt() : 100}%',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isLearning) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCleared
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCleared
                                      ? Colors.green.shade300
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isCleared ? Icons.stars_rounded : Icons.info_outline_rounded,
                                        color: isCleared ? Colors.amber.shade700 : Colors.orange,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isCleared
                                                ? 'Ch.$selectedChapter MASTER! (70pt以上: ${rate.toInt()}%) 🎉'
                                                : 'Ch.$selectedChapter 70pt以上: ${rate.toInt()}% (解放条件: 90%以上)',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isCleared
                                                  ? Colors.green.shade900
                                                  : Colors.brown.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isNewUnlock && nextChapter != null) ...[
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '✨ 次の Chapter $nextChapter が解放されました！ ✨',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '要復習単語（${mistakenWords.length}件）',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C302E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (mistakenWords.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'このミス単語（${mistakenWords.length}語）を特訓する',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9534F),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          final wordsToRetry = List<WordModel>.from(mistakenWords);
                          setState(() {
                            isGameOver = false;
                            isGameStarted = true;
                            remainingTime = totalGameDuration;
                            _unlockResult = null;
                          });
                          _startCountdownSequence(customWords: wordsToRetry);
                        },
                      ),
                    ),
                  ],
                  mistakenWords.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: const Text(
                            'パーフェクト！間違えた単語はありません 🎉',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B726E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mistakenWords.length,
                          itemBuilder: (context, index) {
                            final word = mistakenWords[index];
                            final isFav = favoriteWordIds.contains(word.id);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFFE5DEC9)),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                title: Text(
                                  word.english,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  word.japanese,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.volume_up_rounded,
                                        color: Color(0xFF5F9E98),
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => _playAudio(word),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: isFav ? Colors.amber : Colors.grey,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => _toggleFavorite(word),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),

          // 常に画面最下部に固定表示されるボトムアクションバー
          SafeArea(
            top: false,
            bottom: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF7EE),
                border: Border(top: BorderSide(color: Color(0xFFE5DEC9), width: 1)),
              ),
              child: Row(
                children: [
                  // 左: 選択画面へ
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('選択画面へ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5F9E98),
                          side: const BorderSide(color: Color(0xFF5F9E98), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () {
                          widget.onGameStateChanged?.call(false);
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 中: 再挑戦
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('再挑戦', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2C302E),
                          side: const BorderSide(color: Color(0xFFD0D7DE), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () {
                          setState(() {
                            isGameOver = false;
                            isGameStarted = true;
                            remainingTime = totalGameDuration;
                            _unlockResult = null;
                          });
                          _startCountdownSequence();
                        },
                      ),
                    ),
                  ),

                  // 右: 次のチャプターへ (学習モードで次章が存在・解放される場合)
                  if (isLearning && (nextChapter != null || isCleared || rate >= 90.0)) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '次章 Ch.${nextChapter ?? (selectedChapter + 1)}へ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F9E98),
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed: () {
                            final targetCh = nextChapter ?? (selectedChapter + 1);
                            setState(() {
                              selectedChapter = targetCh;
                              isGameOver = false;
                              isGameStarted = true;
                              remainingTime = totalGameDuration;
                              _unlockResult = null;
                            });
                            _startCountdownSequence();
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLane({
    required bool isLeft,
    required WordModel? word,
    required List<String> choices,
    required Set<String> disabledChoices,
    required AnimationController controller,
    required String? feedback,
    required Color laneColor,
    required Color cardColor,
  }) {
    final displayChoices = choices.isNotEmpty ? choices : List.filled(4, '');

    return Container(
      color: laneColor,
      child: Column(
        children: [
          // 単語が落ちてくるエリア（広々スペース）
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxY = constraints.maxHeight - 44;
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(top: 2, right: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Fast (+50)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(top: 2, right: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Normal (+30)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(top: 2, right: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Slow (+10)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (word != null)
                      AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) {
                          final currentY = controller.value * maxY;
                          return Positioned(
                            top: currentY,
                            left: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        word.english,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _playAudio(word),
                                    child: const Icon(
                                      Icons.volume_up,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    if (feedback != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            feedback,
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // 4択選択肢エリア（広々としたタッチターゲット・快適なタップ領域：高さを1.4倍の59pxに拡大）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F2E7),
              border: Border(top: BorderSide(color: Color(0xFFE5DEC9), width: 1)),
            ),
            child: Column(
              children: List.generate(displayChoices.length, (index) {
                final choice = displayChoices[index];
                final isPlaceholder = choice.isEmpty;
                final isDisabled =
                    isPlaceholder || disabledChoices.contains(choice);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: SizedBox(
                    width: double.infinity,
                    height: 59,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: isPlaceholder
                            ? const Color(0xFFEDE8DC)
                            : Colors.red.shade50,
                        disabledForegroundColor: isPlaceholder
                            ? Colors.transparent
                            : Colors.red.shade700,
                        backgroundColor: isDisabled
                            ? (isPlaceholder
                                  ? const Color(0xFFEDE8DC)
                                  : Colors.red.shade50)
                            : const Color(0xFFFFFDF9),
                        foregroundColor: isDisabled
                            ? (isPlaceholder
                                  ? Colors.transparent
                                  : Colors.red.shade700)
                            : const Color(0xFF2C302E),
                        elevation: isDisabled ? 0 : 1,
                        shadowColor: Colors.black12,
                        side: BorderSide(
                          color: isPlaceholder
                              ? const Color(0xFFE2DCCF)
                              : (isDisabled ? Colors.red.shade300 : const Color(0xFFDCD4BE)),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isDisabled
                          ? null
                          : () => _handleAnswer(
                              isLeft: isLeft,
                              selectedChoice: choice,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            choice,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: (!isPlaceholder && isDisabled)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
