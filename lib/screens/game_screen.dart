// コード管理番号: VER-20260826-01
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/retention_service.dart';
import '../services/sound_service.dart';
import '../services/stamp_service.dart';
import '../services/tts_service.dart';
import '../widgets/stamp_reward_dialog.dart';
import '../widgets/word_detail_modal.dart';

class WordModel {
  final int id;
  final String english;
  final String japanese;
  final String partOfSpeech;
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
    this.partOfSpeech = '',
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

    final pos = driftWord.partOfSpeech.isNotEmpty
        ? driftWord.partOfSpeech
        : AppDatabase.detectPartOfSpeech(driftWord.japanese);

    return WordModel(
      id: driftWord.id,
      english: driftWord.english,
      japanese: driftWord.japanese,
      partOfSpeech: pos,
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
  final String mode; // 'challenge', 'learning', or 'weakness'
  final int initialLevel;
  final List<int>? selectedLevels;
  final int initialChapter;
  final bool autoStart;

  const GameScreen({
    super.key,
    required this.database,
    this.onGameStateChanged,
    this.mode = 'challenge',
    this.initialLevel = 1,
    this.selectedLevels,
    this.initialChapter = 1,
    this.autoStart = true,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final double totalGameDuration = 60.0;
  final int dropDurationSeconds = 8;

  double remainingTime = 60.0;
  int score = 0;
  int combo = 0;
  bool isGameStarted = false;
  bool isGameOver = false;
  bool isPaused = false;
  bool isLoading = true;
  bool _isTimeUpShowing = false;

  late int selectedLevel;
  late int selectedChapter;
  late String currentMode;

  Timer? gameTimer;

  List<WordModel> allWords = [];
  List<WordModel> questionQueue = [];
  List<WordModel> mistakenWords = [];
  final List<WordModel> _playedSessionWords = [];
  final Map<int, List<bool>> _sessionWordAttempts = {};
  List<WordModel> _currentRevengeTargetWords = [];
  List<WordModel> _currentWeaknessTargetWords = [];
  Set<int> favoriteWordIds = {};

  // F-05: 1ゲーム1変動原則（セッション中に既にDB反映・ポイント評価を行った単語IDを記録）
  final Set<int> _processedWordIds = {};
  int _correctCount = 0;
  int _totalAnsweredCount = 0;

  // 要件6: SE重複・最下部到達とタップの排他制御用フラグ
  bool _isLeftProcessing = false;
  bool _isRightProcessing = false;

  WordModel? leftWord;
  List<String> leftChoices = [];
  Set<String> leftDisabledChoices = {};
  late AnimationController _leftDropController;
  DateTime? _leftQuestionStartTime;
  bool isLeftStarted = false;
  bool leftMistaken = false;
  String? leftFeedback;
  String? _leftHighlightCorrect;
  String? _rightHighlightCorrect;

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
    WidgetsBinding.instance.addObserver(this);
    selectedLevel = widget.initialLevel;
    selectedChapter = widget.initialChapter;
    currentMode = widget.mode;

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

  void _playSE(String type) {
    if (type == 'correct' || type.startsWith('correct_')) {
      SoundService.instance.playCorrect();
    } else if (type == 'wrong' || type == 'timeout') {
      SoundService.instance.playWrong();
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
    _playedSessionWords.clear();
    _sessionWordAttempts.clear();
    if (customWords != null && customWords.isNotEmpty) {
      currentMode = 'revenge';
      _currentRevengeTargetWords = List<WordModel>.from(customWords);
      targetWords = List.from(customWords)..shuffle();
      while (targetWords.length < 30) {
        final refill = List<WordModel>.from(customWords)..shuffle();
        targetWords.addAll(refill);
      }
    } else {
      _currentRevengeTargetWords.clear();
      if (currentMode == 'learning') {
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
      // 2. 弱点克服モード: プレイ経験のある単語から苦手単語上位15語を抽出（複数レベル対応）
      final targetLevels = widget.selectedLevels ?? [selectedLevel];
      final filtered = allWords.where((w) => targetLevels.contains(w.level)).toList();
      final pool = filtered.isNotEmpty ? filtered : List<WordModel>.from(allWords);

      final played = pool.where((w) {
        return (w.wrongCount + w.correctCount > 0) || w.retentionPoint > 0;
      }).toList();

      List<WordModel> baseWeaknessList = [];
      if (played.isEmpty) {
        // プレイ経験がまだない場合のフォールバック: 未暗記単語を安全に補充
        final unmemorized = pool.where((w) => !w.isMemorized).toList()..shuffle();
        baseWeaknessList = unmemorized.take(15).toList();
      } else {
        // 弱点候補: 誤答経験あり(wrongCount > 0)、または未暗記/定着度80pt未満
        final weaknessCandidates = played.where((w) {
          return w.wrongCount > 0 || !w.isMemorized || w.retentionPoint < 80;
        }).toList();

        final targetPool = weaknessCandidates.isNotEmpty ? weaknessCandidates : played;

        final List<MapEntry<WordModel, int>> scored = targetPool.map<MapEntry<WordModel, int>>((WordModel w) {
          int weaknessScore = (w.wrongCount * 3);
          if (!w.isMemorized) weaknessScore += 10;
          if (w.retentionPoint < 50) weaknessScore += 10;
          weaknessScore -= w.correctCount.toInt();
          return MapEntry<WordModel, int>(w, weaknessScore);
        }).toList();
        scored.sort((a, b) => b.value.compareTo(a.value));
        baseWeaknessList = scored.map<WordModel>((e) => e.key).take(15).toList();
      }

      _currentWeaknessTargetWords = List<WordModel>.from(baseWeaknessList);
      targetWords = List.from(baseWeaknessList)..shuffle();
      while (targetWords.length < 30 && baseWeaknessList.isNotEmpty) {
        final refill = List<WordModel>.from(baseWeaknessList)..shuffle();
        targetWords.addAll(refill);
      }
    } else {
      // 3. チャレンジモード: 選択中レベルの全単語をシャッフル（複数レベル対応）
      final targetLevels = widget.selectedLevels ?? [selectedLevel];
      targetWords = allWords.where((w) => targetLevels.contains(w.level)).toList();
      if (targetWords.length < 5) {
        targetWords = List.from(allWords);
      }
      targetWords.shuffle();
      }
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

  static String _normalizeChoiceText(String str) {
    // 全角数字を半角数字に統一
    return str.replaceAllMapped(RegExp(r'[０-９]'), (m) {
      final code = m.group(0)!.codeUnitAt(0) - 0xFEE0;
      return String.fromCharCode(code);
    }).trim();
  }

  List<String> _generateChoices(WordModel correctWord) {
    final correctJapanese = _normalizeChoiceText(correctWord.japanese);
    final targetPos = correctWord.partOfSpeech.isNotEmpty
        ? correctWord.partOfSpeech
        : AppDatabase.detectPartOfSpeech(correctWord.japanese);

    // 1. 同一単語の別語義・同スペル単語を完全除外
    final otherWords = allWords.where((w) =>
        w.id != correctWord.id &&
        w.english.toLowerCase().trim() != correctWord.english.toLowerCase().trim()
    ).toList();

    // 2. 同一品詞ダミー厳選（Same-POS Matching: 品詞消去法を防止）
    final samePosCandidates = otherWords
        .where((w) {
          final pos = w.partOfSpeech.isNotEmpty
              ? w.partOfSpeech
              : AppDatabase.detectPartOfSpeech(w.japanese);
          return pos == targetPos;
        })
        .map((w) => _normalizeChoiceText(w.japanese))
        .where((j) => j.isNotEmpty && j != correctJapanese)
        .toSet()
        .toList()..shuffle();

    final List<String> wrongChoices = [];
    if (samePosCandidates.length >= 3) {
      wrongChoices.addAll(samePosCandidates.take(3));
    } else {
      wrongChoices.addAll(samePosCandidates);
      // 足りない場合は他の品詞から安全に補填
      final remainingCandidates = otherWords
          .map((w) => _normalizeChoiceText(w.japanese))
          .where((j) => j.isNotEmpty && j != correctJapanese && !wrongChoices.contains(j))
          .toSet()
          .toList()..shuffle();
      for (final rem in remainingCandidates) {
        if (wrongChoices.length >= 3) break;
        wrongChoices.add(rem);
      }
    }

    // 3. 万が一候補が3つに満たない場合の安全なフォールバック
    const fallbackList = [
      '走る', '話す', '歩く', '食べる', '本', '水', '空', '時間', '友達', '家', '学校', '音楽'
    ];
    for (final fb in fallbackList) {
      if (wrongChoices.length >= 3) break;
      final norm = _normalizeChoiceText(fb);
      if (norm != correctJapanese && !wrongChoices.contains(norm)) {
        wrongChoices.add(norm);
      }
    }

    // 4. 正解を含めて4つの選択肢をシャッフル
    final choices = [...wrongChoices, correctJapanese]..shuffle();
    return choices;
  }

  void _nextQuestion({required bool isLeft}) {
    if (isLeft) {
      _isLeftProcessing = false;
    } else {
      _isRightProcessing = false;
    }

    if (questionQueue.isEmpty && !isGameOver && isGameStarted) {
      if (currentMode == 'revenge' && _currentRevengeTargetWords.isNotEmpty) {
        // リベンジモード: 1分間最後まで特訓を継続するため自動でシャッフル補充
        final refill = List<WordModel>.from(_currentRevengeTargetWords)..shuffle();
        questionQueue.addAll(refill);
      } else if (currentMode == 'weakness' && _currentWeaknessTargetWords.isNotEmpty) {
        // 弱点克服モード: 15単語を1分間最後まで特訓を継続するため自動でシャッフル補充
        final refill = List<WordModel>.from(_currentWeaknessTargetWords)..shuffle();
        questionQueue.addAll(refill);
      }
    }

    if (questionQueue.isEmpty || isGameOver || !isGameStarted) {
      if (leftWord == null && rightWord == null) {
        _endGame();
      }
      return;
    }

    final nextWord = questionQueue.removeAt(0);
    if (!_playedSessionWords.any((w) => w.id == nextWord.id)) {
      _playedSessionWords.add(nextWord);
    }
    final choices = _generateChoices(nextWord);

    setState(() {
      if (isLeft) {
        leftWord = nextWord;
        leftChoices = choices;
        leftDisabledChoices.clear();
        leftMistaken = false;
        leftFeedback = null;
        _leftHighlightCorrect = null;
      } else {
        rightWord = nextWord;
        rightChoices = choices;
        rightDisabledChoices.clear();
        rightMistaken = false;
        rightFeedback = null;
        _rightHighlightCorrect = null;
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


  void _handleDontKnow({required bool isLeft}) {
    if (isLeft) {
      if (_isLeftProcessing) return;
      _isLeftProcessing = true;
    } else {
      if (_isRightProcessing) return;
      _isRightProcessing = true;
    }

    final targetWord = isLeft ? leftWord : rightWord;
    final controller = isLeft ? _leftDropController : _rightDropController;

    if (targetWord == null || isPaused || !isGameStarted || _isEnding || _isTimeUpShowing || isGameOver) {
      if (isLeft) {
        _isLeftProcessing = false;
      } else {
        _isRightProcessing = false;
      }
      return;
    }

    controller.stop();
    _playSE('wrong');
    _recordMistake(targetWord);
    _sessionWordAttempts.putIfAbsent(targetWord.id, () => []).add(false);

    if (!_processedWordIds.contains(targetWord.id)) {
      _processedWordIds.add(targetWord.id);
      widget.database.updateWordQuizResult(
        id: targetWord.id,
        dropProgress: 1.0,
        isCorrect: false,
      );
    }

    final normCorrect = _normalizeChoiceText(targetWord.japanese);
    setState(() {
      combo = 0;
      _totalAnsweredCount += 1;
      if (isLeft) {
        leftMistaken = true;
        leftFeedback = "パス (不正解)";
        _leftHighlightCorrect = normCorrect;
        leftDisabledChoices.addAll(leftChoices.where((c) => _normalizeChoiceText(c) != normCorrect));
      } else {
        rightMistaken = true;
        rightFeedback = "パス (不正解)";
        _rightHighlightCorrect = normCorrect;
        rightDisabledChoices.addAll(rightChoices.where((c) => _normalizeChoiceText(c) != normCorrect));
      }
    });

    questionQueue.add(targetWord);

    // 1.0秒間正解をハイライトした後に次問へ遷移
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || isGameOver || !isGameStarted) return;
      setState(() {
        if (isLeft) {
          leftWord = null;
          leftChoices = [];
          _leftHighlightCorrect = null;
        } else {
          rightWord = null;
          rightChoices = [];
          _rightHighlightCorrect = null;
        }
      });
      _nextQuestion(isLeft: isLeft);
    });
  }

  void _handleAnswer({required bool isLeft, required String selectedChoice}) {
    // 要件6: タップと最下部判定の排他制御（SE重複・二重処理防止）
    if (isLeft) {
      if (_isLeftProcessing) return;
      _isLeftProcessing = true;
    } else {
      if (_isRightProcessing) return;
      _isRightProcessing = true;
    }

    final targetWord = isLeft ? leftWord : rightWord;
    final controller = isLeft ? _leftDropController : _rightDropController;

    if (targetWord == null || isPaused || !isGameStarted || _isEnding || _isTimeUpShowing || isGameOver) {
      if (isLeft) {
        _isLeftProcessing = false;
      } else {
        _isRightProcessing = false;
      }
      return;
    }

    final isCorrectAnswer = (_normalizeChoiceText(selectedChoice) == _normalizeChoiceText(targetWord.japanese));

    if (isCorrectAnswer) {
      // 正解の選択肢のみをハイライト
      if (isLeft) {
        _leftHighlightCorrect = _normalizeChoiceText(targetWord.japanese);
      } else {
        _rightHighlightCorrect = _normalizeChoiceText(targetWord.japanese);
      }

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
      _sessionWordAttempts.putIfAbsent(targetWord.id, () => []).add(!wasMistaken);
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

      // 誤答時は次の選択肢をタップできるようロック解除
      if (isLeft) {
        _isLeftProcessing = false;
      } else {
        _isRightProcessing = false;
      }
    }
  }

  void _handleTimeOut({required bool isLeft}) {
    // 要件6: タップと最下部判定の排他制御
    if (isLeft) {
      if (_isLeftProcessing) return;
      _isLeftProcessing = true;
    } else {
      if (_isRightProcessing) return;
      _isRightProcessing = true;
    }

    if (!isGameStarted || isGameOver || isPaused) {
      if (isLeft) {
        _isLeftProcessing = false;
      } else {
        _isRightProcessing = false;
      }
      return;
    }
    final targetWord = isLeft ? leftWord : rightWord;
    if (targetWord == null) {
      if (isLeft) {
        _isLeftProcessing = false;
      } else {
        _isRightProcessing = false;
      }
      return;
    }

    // Safari等のTicker跳躍/誤完了ガード（落下開始から実時間で最低40%以上経過していない異常トリガーは無視して復元）
    final startTime = isLeft ? _leftQuestionStartTime : _rightQuestionStartTime;
    if (startTime != null) {
      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsedMs < (dropDurationSeconds * 1000 * 0.4).toInt()) {
        final controller = isLeft ? _leftDropController : _rightDropController;
        final correctProgress = (elapsedMs / (dropDurationSeconds * 1000.0)).clamp(0.0, 1.0);
        controller.value = correctProgress;
        controller.forward();
        if (isLeft) {
          _isLeftProcessing = false;
        } else {
          _isRightProcessing = false;
        }
        return;
      }
    }

    _playSE('timeout');
    _recordMistake(targetWord);
    _sessionWordAttempts.putIfAbsent(targetWord.id, () => []).add(false);

    // F-05: タイムオーバー時も初回であれば誤答扱いとしてDB更新（制限フラグ付与等）
    if (!_processedWordIds.contains(targetWord.id)) {
      _processedWordIds.add(targetWord.id);
      widget.database.updateWordQuizResult(
        id: targetWord.id,
        dropProgress: 1.0,
        isCorrect: false,
      );
    }

    final normCorrect = _normalizeChoiceText(targetWord.japanese);
    setState(() {
      combo = 0;
      _totalAnsweredCount += 1;
      if (isLeft) {
        leftMistaken = true;
        leftFeedback = "タイムオーバー!";
        _leftHighlightCorrect = normCorrect;
        leftDisabledChoices.addAll(leftChoices.where((c) => _normalizeChoiceText(c) != normCorrect));
      } else {
        rightMistaken = true;
        rightFeedback = "タイムオーバー!";
        _rightHighlightCorrect = normCorrect;
        rightDisabledChoices.addAll(rightChoices.where((c) => _normalizeChoiceText(c) != normCorrect));
      }
    });

    questionQueue.add(targetWord);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || isGameOver || !isGameStarted) return;
      setState(() {
        if (isLeft) {
          leftWord = null;
          leftChoices = [];
          _leftHighlightCorrect = null;
        } else {
          rightWord = null;
          rightChoices = [];
          _rightHighlightCorrect = null;
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

    // 1. タイムアップ演出開始（中央に「TIME UP!」ポップアップ、操作ロック）
    if (mounted) {
      setState(() {
        remainingTime = 0.0;
        _isTimeUpShowing = true;
        isPaused = false;
      });
    }

    // 1.2秒間のタイムアップ待機（回答タップ連打によるリザルト画面ボタン誤タップを100%防止）
    await Future.delayed(const Duration(milliseconds: 1200));

    // 2. DB処理（学習履歴保存、チャプター解放、スタンプ判定）
    try {
      await widget.database.addGameHistory(score, selectedLevel);
    } catch (e) {
      debugPrint("addGameHistory error: $e");
    }

    Map<String, dynamic>? unlockResult;
    try {
      if (currentMode == 'learning') {
        unlockResult = await widget.database.checkAndUnlockNextChapter(selectedChapter);
      }
    } catch (e) {
      debugPrint("checkAndUnlockNextChapter error: $e");
    }

    Stamp? awardedStamp;
    try {
      final stampService = StampService(database: widget.database);
      awardedStamp = await stampService.checkAndAwardDailyStamp();
    } catch (e) {
      debugPrint("Daily Stamp Award Error: $e");
    }

    // 3. リザルト画面へスムーズに遷移
    if (mounted) {
      setState(() {
        _isTimeUpShowing = false;
        isGameOver = true;
        isGameStarted = false;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (isGameStarted && !isGameOver && !isPaused && !_isEnding && !_isTimeUpShowing) {
        _togglePause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetAndStopAll();
    _countdownAnimController.dispose();
    _leftDropController.dispose();
    _rightDropController.dispose();
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
        : (currentMode == 'revenge'
            ? 'ミス単語リベンジ (${_currentRevengeTargetWords.length}語)'
            : (currentMode == 'weakness' ? '弱点克服モード (15語)' : 'チャレンジモード'));

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
                          if (_isTimeUpShowing)
                            _buildTimeUpOverlay(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeUpOverlay() {
    return Container(
      color: Colors.black.withAlpha(120),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCF7067), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_off_rounded,
                    color: Color(0xFFCF7067),
                    size: 44,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'TIME UP!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFCF7067),
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '制限時間終了',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C302E),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  Widget _buildAttemptBadges(List<bool> attempts) {
    if (attempts.isEmpty) return const SizedBox.shrink();

    if (attempts.length == 1) {
      final isCorrect = attempts.first;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCorrect ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 12,
              color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
            const SizedBox(width: 3),
            Text(
              isCorrect ? '正解' : '不正解',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: attempts.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final isCorrect = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isCorrect ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$idx回目: ',
                style: TextStyle(
                  fontSize: 10,
                  color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                isCorrect ? Icons.check_rounded : Icons.close_rounded,
                size: 12,
                color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultScreen() {
    final isLearning = currentMode == 'learning';
    final rate = (_unlockResult?['memorizedRate'] as double?) ?? 0.0;
    final isCleared = (_unlockResult?['isCleared'] as bool?) ?? false;
    final nextChapter = _unlockResult?['nextChapterUnlocked'] as int?;
    final isNewUnlock = (_unlockResult?['isNewUnlock'] as bool?) ?? false;

    // ミス単語リベンジモードおよび弱点克服モード時は出題単語を表示
    final isShowPlayedWords = (currentMode == 'revenge' || currentMode == 'weakness');
    final List<WordModel> displayWords = isShowPlayedWords
        ? (_playedSessionWords.isNotEmpty
            ? _playedSessionWords
            : (_currentRevengeTargetWords.isNotEmpty
                ? _currentRevengeTargetWords
                : (_currentWeaknessTargetWords.isNotEmpty ? _currentWeaknessTargetWords : mistakenWords)))
        : mistakenWords;

    final String headerTitle = isShowPlayedWords
        ? '出題単語（${displayWords.length}件）'
        : '要復習単語（${displayWords.length}件）';

    final bool showActionButton = currentMode == 'revenge'
        ? displayWords.isNotEmpty
        : mistakenWords.isNotEmpty;

    final String actionButtonText = currentMode == 'revenge'
        ? '同じ問題を解きなおす'
        : 'ミス単語リベンジ';

    final IconData actionButtonIcon = currentMode == 'revenge'
        ? Icons.replay_rounded
        : Icons.flash_on_rounded;

    return Container(
      color: const Color(0xFFFBF7EE),
      child: Column(
        children: [
          // スクロール可能なリザルトカード ＆ ピン留めヘッダー付き単語リスト
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. スコアサマリーカード
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 4.0),
                  sliver: SliverToBoxAdapter(
                    child: Card(
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
                                          '✨ 次の Ch.$nextChapter が解放されました！ ✨',
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
                  ),
                ),

                // 2. スクロールしても上に固定表示され続ける見出し ＆ リベンジボタン
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ResultListHeaderDelegate(
                    title: headerTitle,
                    buttonText: actionButtonText,
                    buttonIcon: actionButtonIcon,
                    showButton: showActionButton,
                    onButtonPressed: () {
                      if (currentMode == 'revenge') {
                        List<WordModel> wordsToRetry = mistakenWords.isNotEmpty
                            ? List<WordModel>.from(mistakenWords)
                            : List<WordModel>.from(displayWords);
                        if (wordsToRetry.length <= 5 && _currentRevengeTargetWords.isNotEmpty) {
                          final additional = _currentRevengeTargetWords.where((w) => !wordsToRetry.any((mw) => mw.id == w.id)).toList()..shuffle();
                          for (final add in additional) {
                            if (wordsToRetry.length >= 6) break;
                            wordsToRetry.add(add);
                          }
                        }
                        setState(() {
                          isGameOver = false;
                          isGameStarted = true;
                          remainingTime = totalGameDuration;
                          _unlockResult = null;
                        });
                        _startCountdownSequence(customWords: wordsToRetry.isNotEmpty ? wordsToRetry : _currentRevengeTargetWords);
                      } else {
                        List<WordModel> wordsToRetry = List<WordModel>.from(mistakenWords);
                        if (wordsToRetry.length <= 5) {
                          final currentPool = (widget.mode == 'learning')
                              ? allWords.where((w) => w.chapter == selectedChapter).toList()
                              : allWords.where((w) => (widget.selectedLevels ?? [selectedLevel]).contains(w.level)).toList();
                          final additional = currentPool.where((w) => !wordsToRetry.any((mw) => mw.id == w.id)).toList()..shuffle();
                          for (final add in additional) {
                            if (wordsToRetry.length >= 6) break;
                            wordsToRetry.add(add);
                          }
                        }
                        setState(() {
                          isGameOver = false;
                          isGameStarted = true;
                          remainingTime = totalGameDuration;
                          _unlockResult = null;
                        });
                        _startCountdownSequence(customWords: wordsToRetry);
                      }
                    },
                  ),
                ),

                // 3. 単語リスト一覧
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14.0, 4.0, 14.0, 12.0),
                  sliver: displayWords.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: Text(
                              isShowPlayedWords
                                  ? '出題された単語はありません'
                                  : 'パーフェクト！間違えた単語はありません 🎉',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B726E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final word = displayWords[index];
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
                                  onTap: () async {
                                    final allDbWords = await widget.database.getAllWords();
                                    final modalWordList = displayWords.map((mw) {
                                      return allDbWords.firstWhere(
                                        (w) => w.id == mw.id,
                                        orElse: () => Word(
                                          id: mw.id,
                                          level: mw.level,
                                          chapter: mw.chapter,
                                          english: mw.english,
                                          japanese: mw.japanese,
                                          partOfSpeech: mw.partOfSpeech,
                                          cefr: 'A1',
                                          category: 'General',
                                          phonetic: '',
                                          example: '',
                                          exampleJp: '',
                                          collocations: '[]',
                                          otherMeanings: '[]',
                                          retentionPoint: mw.retentionPoint,
                                          pointDecreasedTotal: 0,
                                          isMemorized: mw.isMemorized,
                                          isRestricted: mw.isRestricted,
                                          isFavorite: isFav,
                                          correctCount: mw.correctCount,
                                          wrongCount: mw.wrongCount,
                                          lastStudiedAt: null,
                                        ),
                                      );
                                    }).toList();

                                    if (context.mounted) {
                                      WordDetailModal.show(
                                        context: context,
                                        wordList: modalWordList,
                                        initialIndex: index,
                                        database: widget.database,
                                        onFavoriteChanged: () {
                                          setState(() {
                                            if (favoriteWordIds.contains(word.id)) {
                                              favoriteWordIds.remove(word.id);
                                              word.isFavorite = false;
                                            } else {
                                              favoriteWordIds.add(word.id);
                                              word.isFavorite = true;
                                            }
                                          });
                                        },
                                      );
                                    }
                                  },
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          word.english,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (isShowPlayedWords) ...[
                                        const SizedBox(width: 8),
                                        _buildAttemptBadges(_sessionWordAttempts[word.id] ?? []),
                                      ],
                                    ],
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
                            childCount: displayWords.length,
                          ),
                        ),
                ),
              ],
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

                  // 中: 再挑戦（通常時） / ゲーム選択画面で選択したセクションをはじめから開始（リベンジ時）
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          currentMode == 'revenge' ? Icons.school_rounded : Icons.refresh_rounded,
                          size: 18,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currentMode == 'revenge'
                                ? (widget.mode == 'learning'
                                    ? 'Chapter $selectedChapter を学習開始'
                                    : '選択セクションをはじめから開始')
                                : '再挑戦',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentMode == 'revenge' ? const Color(0xFF5F9E98) : const Color(0xFFECA882),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () {
                          setState(() {
                            if (currentMode == 'revenge') {
                              currentMode = widget.mode;
                            }
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
                              currentMode = 'learning';
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
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F2E7),
              border: Border(top: BorderSide(color: Color(0xFFE5DEC9), width: 1)),
            ),
            child: Column(
              children: [
                ...List.generate(displayChoices.length, (index) {
                  final choice = displayChoices[index];
                  final isPlaceholder = choice.isEmpty;
                  final normChoice = _normalizeChoiceText(choice);
                  final highlightedCorrect = isLeft ? _leftHighlightCorrect : _rightHighlightCorrect;
                  final isCorrectHighlighted = highlightedCorrect != null && highlightedCorrect == normChoice && normChoice.isNotEmpty;
                  final isMistakenChoice = disabledChoices.contains(choice);
                  final isLaneProcessing = (isLeft ? _isLeftProcessing : _isRightProcessing);
                  final isButtonDisabled = isPlaceholder || isMistakenChoice || isLaneProcessing;

                  Color btnBgColor;
                  Color btnFgColor;
                  Color btnBorderColor;
                  double btnBorderWidth = 1.2;

                  if (isPlaceholder) {
                    btnBgColor = const Color(0xFFEDE8DC);
                    btnFgColor = Colors.transparent;
                    btnBorderColor = const Color(0xFFE2DCCF);
                  } else if (isCorrectHighlighted) {
                    // 正解時: 誤答時と同じトーンの薄緑ハイライト
                    btnBgColor = Colors.green.shade50;
                    btnFgColor = Colors.green.shade800;
                    btnBorderColor = Colors.green.shade300;
                    btnBorderWidth = 1.5;
                  } else if (isMistakenChoice) {
                    btnBgColor = Colors.red.shade50; // 誤答時: 赤薄＋赤文字
                    btnFgColor = Colors.red.shade700;
                    btnBorderColor = Colors.red.shade300;
                  } else {
                    btnBgColor = const Color(0xFFFFFDF9); // 通常・未タップ
                    btnFgColor = const Color(0xFF2C302E);
                    btnBorderColor = const Color(0xFFDCD4BE);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: btnBgColor,
                          disabledForegroundColor: btnFgColor,
                          backgroundColor: btnBgColor,
                          foregroundColor: btnFgColor,
                          elevation: (isPlaceholder || isMistakenChoice) ? 0 : 1,
                          shadowColor: Colors.black12,
                          side: BorderSide(
                            color: btnBorderColor,
                            width: btnBorderWidth,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isButtonDisabled
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
                                decoration: (!isPlaceholder && isMistakenChoice && !isCorrectHighlighted)
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
                // 「わからない」ボタン（即座に正解を1秒ハイライト表示して不正解遷移）
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.help_outline_rounded, size: 13, color: Color(0xFF8C827A)),
                      label: const Text(
                        'わからない',
                        style: TextStyle(fontSize: 11, color: Color(0xFF5A524C), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFEFE8DA),
                        side: const BorderSide(color: Color(0xFFDCD4BE), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: (word == null || (isLeft ? _isLeftProcessing : _isRightProcessing))
                          ? null
                          : () => _handleDontKnow(isLeft: isLeft),
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
}

class _ResultListHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? buttonText;
  final IconData buttonIcon;
  final bool showButton;
  final VoidCallback? onButtonPressed;

  _ResultListHeaderDelegate({
    required this.title,
    this.buttonText,
    required this.buttonIcon,
    required this.showButton,
    this.onButtonPressed,
  });

  @override
  double get minExtent => showButton ? 88.0 : 36.0;

  @override
  double get maxExtent => showButton ? 88.0 : 36.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFBF7EE),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C302E),
            ),
          ),
          if (showButton && buttonText != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                icon: Icon(buttonIcon, color: Colors.white, size: 18),
                label: Text(
                  buttonText!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCF7067),
                  foregroundColor: Colors.white,
                  elevation: overlapsContent ? 2 : 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: onButtonPressed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ResultListHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.buttonText != buttonText ||
        oldDelegate.buttonIcon != buttonIcon ||
        oldDelegate.showButton != showButton;
  }
}
