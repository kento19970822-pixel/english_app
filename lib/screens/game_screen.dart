// コード管理番号: VER-20260818-15
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../db/app_database.dart';
import '../services/retention_service.dart';

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

  @override
  void initState() {
    super.initState();
    selectedLevel = widget.initialLevel;
    selectedChapter = widget.initialChapter;
    currentMode = widget.mode;

    _seAudioPlayer = AudioPlayer();
    _initTts();

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
        _startGame();
      }
    });
  }

  Future<void> _loadWordsFromDb() async {
    final dbWords = await widget.database.getAllWords();
    setState(() {
      allWords = dbWords.map((w) => WordModel.fromDrift(w)).toList();
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
    gameTimer?.cancel();
    gameTimer = null;
    _leftStartTimer?.cancel();
    _leftStartTimer = null;

    _leftDropController.stop();
    _leftDropController.reset();
    _rightDropController.stop();
    _rightDropController.reset();
  }

  void _startGame() async {
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

    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isPaused) return;
      if (remainingTime > 0.1) {
        setState(() {
          remainingTime -= 0.1;
        });
      } else {
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
    List<WordModel> candidateWords = allWords
        .where(
          (w) => w.id != correctWord.id && w.japanese != correctWord.japanese,
        )
        .toList();
    candidateWords.shuffle();

    List<String> choices = candidateWords
        .take(3)
        .map((w) => w.japanese)
        .toList();
    choices.add(correctWord.japanese);
    choices.shuffle();
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

      // F-04: 位置判定加点 (+50 / +30 / +10) ＋ コンボボーナス
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
      final result = RetentionService.calculateScoreAndRetention(
        dropProgress: controller.value,
        isCorrect: false,
      );

      _playSE(result['soundType'] as String);
      _recordMistake(targetWord);

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
        title: const Text('一時停止中', textAlign: TextAlign.center),
        content: const Text('ゲームが停止しています。', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _togglePause();
            },
            child: const Text('再開する', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _cancelGame();
            },
            child: const Text('ゲーム中止'),
          ),
        ],
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

  void _endGame() {
    _resetAndStopAll();

    if (score > 0) {
      widget.database.addGameHistory(score, selectedLevel);
    }

    setState(() {
      isGameOver = true;
      isPaused = false;
    });
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
    _leftDropController.dispose();
    _rightDropController.dispose();
    _seAudioPlayer.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          title: Text(modeTitle),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (isGameStarted && !isGameOver)
              IconButton(
                icon: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  size: 28,
                  color: Colors.indigo,
                ),
                onPressed: _togglePause,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '残り時間: ${max(0, remainingTime).toStringAsFixed(1)}s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remainingTime <= 10 ? Colors.red : Colors.black,
                      ),
                    ),
                    if (combo > 1)
                      Text(
                        '$combo COMBO!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    Text(
                      'スコア: $score',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: isGameOver
                    ? _buildResultScreen()
                    : Row(
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
                              cardColor: Colors.blue.shade600,
                            ),
                          ),
                          const VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: Colors.grey,
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
                              cardColor: Colors.indigo.shade600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'ゲーム終了！',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '最終スコア: $score',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '要復習単語（${mistakenWords.length}件）',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: mistakenWords.isEmpty
                ? const Center(
                    child: Text(
                      'パーフェクト！間違えた単語はありません 🎉',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: mistakenWords.length,
                    itemBuilder: (context, index) {
                      final word = mistakenWords[index];
                      final isFav = favoriteWordIds.contains(word.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            word.english,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(word.japanese),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: Colors.indigo,
                                ),
                                onPressed: () => _playAudio(word),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.star : Icons.star_border,
                                  color: isFav ? Colors.amber : Colors.grey,
                                ),
                                onPressed: () => _toggleFavorite(word),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onGameStateChanged?.call(false);
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'モード選択へ戻る',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxY = constraints.maxHeight - 60;
                return Stack(
                  children: [
                    // F-04: 3分割判定線（Fast / Normal / Slow）とエリアガイド表示
                    Column(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(top: 4, right: 6),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Text(
                              'Fast (+50)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(top: 4, right: 6),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Text(
                              'Normal (+30)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(top: 4, right: 6),
                            child: Text(
                              'Slow (+10)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800.withValues(
                                  alpha: 0.4,
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
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
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
                                  Text(
                                    word.english,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _playAudio(word),
                                    child: const Icon(
                                      Icons.volume_up,
                                      color: Colors.white70,
                                      size: 20,
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
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            feedback,
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            color: Colors.white,
            child: Column(
              children: List.generate(displayChoices.length, (index) {
                final choice = displayChoices[index];
                final isPlaceholder = choice.isEmpty;
                final isDisabled =
                    isPlaceholder || disabledChoices.contains(choice);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
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
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isDisabled
                          ? null
                          : () => _handleAnswer(
                              isLeft: isLeft,
                              selectedChoice: choice,
                            ),
                      child: Text(
                        choice,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: (!isPlaceholder && isDisabled)
                              ? TextDecoration.lineThrough
                              : null,
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
