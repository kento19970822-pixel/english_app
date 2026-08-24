// コード管理番号: VER-20260824-34
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../db/app_database.dart';
import '../services/retention_service.dart';
import '../services/stamp_service.dart';
import '../widgets/stamp_reward_dialog.dart';

class WordModel {
  final int id;
  final String english;
  final String japanese;
  final int level;
  final int chapter;
  bool isFavorite;

  WordModel({
    required this.id,
    required this.english,
    required this.japanese,
    required this.level,
    required this.chapter,
    this.isFavorite = false,
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
      isFavorite: driftWord.isFavorite,
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
  final FlutterTts flutterTts = FlutterTts();
  late AudioPlayer _seAudioPlayer;

  bool _isTtsInitialized = false;

  List<WordModel> allWords = [];
  List<WordModel> questionQueue = [];
  List<WordModel> mistakenWords = [];
  Set<int> favoriteWordIds = {};

  // F-05: 1ゲーム1変動原則（セッション中に既にDB反映・ポイント評価を行った単語IDを記録）
  final Set<int> _processedWordIds = {};

  WordModel? leftWord;
  List<String> leftChoices = [];
  Set<String> leftDisabledChoices = {};
  late AnimationController _leftDropController;
  bool isLeftStarted = false;
  bool leftMistaken = false;
  String? leftFeedback;

  WordModel? rightWord;
  List<String> rightChoices = [];
  Set<String> rightDisabledChoices = {};
  late AnimationController _rightDropController;
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
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    } finally {
      _isTtsInitialized = true;
    }
  }

  Future<void> _playAudio(WordModel word) async {
    try {
      if (_isTtsInitialized) {
        await flutterTts.stop();
        await flutterTts.speak(word.english);
      }
    } catch (e) {
      debugPrint("TTS Play Error: $e");
    }
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
        await _seAudioPlayer.stop();
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

    _leftDropController.stop();
    _leftDropController.reset();
    _rightDropController.stop();
    _rightDropController.reset();
  }

  void _startCountdownSequence() async {
    _resetAndStopAll();

    List<WordModel> targetWords = [];
    if (currentMode == 'learning') {
      targetWords = allWords
          .where(
            (w) => w.level == selectedLevel && w.chapter == selectedChapter,
          )
          .toList();
    } else {
      targetWords = allWords.where((w) => w.level == selectedLevel).toList();
    }

    if (targetWords.length < 5) {
      targetWords = List.from(allWords);
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
      isGameStarted = true;
      remainingTime = totalGameDuration;
      score = 0;
      combo = 0;
      isGameOver = false;
      isPaused = false;
      isLeftStarted = false;
      questionQueue = List.from(targetWords)..shuffle();
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
      if (isPaused) return;
      if (remainingTime > 0.15) {
        setState(() {
          remainingTime -= 0.1;
        });
      } else {
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

    if (isLeft) {
      _leftDropController.reset();
      _leftDropController.forward();
    } else {
      _rightDropController.reset();
      _rightDropController.forward();
    }
  }

  void _handleAnswer({required bool isLeft, required String selectedChoice}) {
    final targetWord = isLeft ? leftWord : rightWord;
    final controller = isLeft ? _leftDropController : _rightDropController;

    if (targetWord == null || isPaused || !isGameStarted) return;

    if (selectedChoice == targetWord.japanese) {
      final double progress = controller.value;
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
      final progress = controller.value;
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
    final targetWord = isLeft ? leftWord : rightWord;
    if (targetWord == null || !isGameStarted) return;

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
    setState(() {
      isPaused = !isPaused;
    });

    if (isPaused) {
      _leftDropController.stop();
      _rightDropController.stop();
      _showPauseDialog();
    } else {
      if (leftWord != null) _leftDropController.forward();
      if (rightWord != null) _rightDropController.forward();
    }
  }

  void _showPauseDialog() {
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
                  '最初からやり直す (リスタート)',
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

  void _endGame() async {
    _resetAndStopAll();

    // F-10: 本日のプレイ回数加算と学習履歴の保存
    await widget.database.addGameHistory(score, selectedLevel);

    // F-15: 学習モードの場合、チャプター暗記率判定および次チャプター解放処理を実行
    Map<String, dynamic>? unlockResult;
    if (currentMode == 'learning') {
      unlockResult = await widget.database.checkAndUnlockNextChapter(selectedChapter);
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
        remainingTime = 0.0;
        _unlockResult = unlockResult;
        isGameOver = true;
        isPaused = false;
      });

      if (awardedStamp != null) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
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
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5F9E98))));
    }

    final modeTitle = currentMode == 'learning'
        ? '学習モード (Ch.$selectedChapter)'
        : 'チャレンジモード';

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
                                                ? 'Ch.$selectedChapter MASTER! (${rate.toInt()}%) 🎉'
                                                : 'Ch.$selectedChapter 暗記率: ${rate.toInt()}% (目標: >90%)',
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

          // 常に画面最下部に固定表示されるボトムアクションバー（左: 選択画面へ, 右: 再挑戦）
          Container(
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
                const SizedBox(width: 10),
                // 右: 再挑戦
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('再挑戦', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        setState(() {
                          isGameOver = false;
                          isGameStarted = true;
                          remainingTime = totalGameDuration;
                        });
                        _startCountdownSequence();
                      },
                    ),
                  ),
                ),
              ],
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

          // 4択選択肢エリア（スリム化して単語落下エリアを広く確保）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            color: Colors.white,
            child: Column(
              children: List.generate(displayChoices.length, (index) {
                final choice = displayChoices[index];
                final isPlaceholder = choice.isEmpty;
                final isDisabled =
                    isPlaceholder || disabledChoices.contains(choice);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: isPlaceholder
                            ? Colors.grey[100]
                            : Colors.red.shade100,
                        disabledForegroundColor: isPlaceholder
                            ? Colors.transparent
                            : Colors.red.shade700,
                        backgroundColor: isDisabled
                            ? (isPlaceholder
                                  ? Colors.grey[100]
                                  : Colors.red.shade100)
                            : Colors.grey[100],
                        foregroundColor: isDisabled
                            ? (isPlaceholder
                                  ? Colors.transparent
                                  : Colors.red.shade700)
                            : Colors.black87,
                        elevation: 0,
                        side: BorderSide(
                          color: isPlaceholder
                              ? Colors.grey.shade300
                              : Colors.transparent,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
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
                              fontSize: 12,
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
