// コード管理番号: VER-20260816-92
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../db/app_database.dart';

class WordModel {
  final int id; // int型へ統一
  final String english;
  final String japanese;
  final int level; // 1: 初級, 2: 中級, 3: 上級
  bool isFavorite;

  WordModel({
    required this.id,
    required this.english,
    required this.japanese,
    required this.level,
    this.isFavorite = false,
  });

  factory WordModel.fromDrift(Word driftWord) {
    int parsedLevel = 1;
    final cefr = driftWord.cefr.toUpperCase().trim();

    if (cefr.contains('A1') || cefr.contains('A2') || cefr == '1') {
      parsedLevel = 1;
    } else if (cefr.contains('B1') || cefr.contains('B2') || cefr == '2') {
      parsedLevel = 2;
    } else if (cefr.contains('C1') || cefr.contains('C2') || cefr == '3') {
      parsedLevel = 3;
    } else {
      parsedLevel = 1;
    }

    return WordModel(
      id: driftWord.id,
      english: driftWord.english,
      japanese: driftWord.japanese,
      level: parsedLevel,
      isFavorite: driftWord.isFavorite,
    );
  }
}

class GameScreen extends StatefulWidget {
  final AppDatabase database;
  final Function(bool isStarted)? onGameStateChanged;

  const GameScreen({
    super.key,
    required this.database,
    this.onGameStateChanged,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final double totalGameDuration = 60.0;
  final int dropDurationSeconds = 10;

  double remainingTime = 60.0;
  int score = 0;
  int combo = 0;
  bool isGameStarted = false;
  bool isGameOver = false;
  bool isPaused = false;
  bool isLoading = true;

  int selectedLevel = 1;

  Timer? gameTimer;
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer _seAudioPlayer = AudioPlayer();

  bool _isTtsInitialized = false;

  List<WordModel> allWords = [];
  List<WordModel> questionQueue = [];

  List<WordModel> mistakenWords = [];
  Set<int> favoriteWordIds = {}; // int型へ変更

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
    _loadWordsFromDb();
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
  }

  Future<void> _loadWordsFromDb() async {
    final dbWords = await widget.database.getAllWords();

    setState(() {
      allWords = dbWords.map((w) => WordModel.fromDrift(w)).toList();
      favoriteWordIds = dbWords
          .where((w) => w.isFavorite)
          .map((w) => w.id)
          .toSet();
      isLoading = false;
    });
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.45);
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
      String soundUrl = "";
      if (type == 'correct') {
        soundUrl =
            "https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3";
      } else if (type == 'wrong') {
        soundUrl =
            "https://assets.mixkit.co/active_storage/sfx/2003/2003-preview.mp3";
      } else if (type == 'timeout') {
        soundUrl =
            "https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3";
      }

      if (soundUrl.isNotEmpty && !kIsWeb) {
        await _seAudioPlayer.stop();
        await _seAudioPlayer.play(UrlSource(soundUrl));
      }
    } catch (e) {
      debugPrint("SE Error: $e");
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

  void _startGame() {
    _resetAndStopAll();

    List<WordModel> levelWords = allWords
        .where((w) => w.level == selectedLevel)
        .toList();

    if (levelWords.length < 5) {
      levelWords = List.from(allWords);
    }

    setState(() {
      isGameStarted = true;
      remainingTime = totalGameDuration;
      score = 0;
      combo = 0;
      isGameOver = false;
      isPaused = false;
      isLeftStarted = false;
      questionQueue = List.from(levelWords)..shuffle();
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
      controller.stop();
      _playSE('correct');

      final dropProgress = controller.value;
      int addScore = 1;
      if (dropProgress < 0.33) {
        addScore = 3;
      } else if (dropProgress < 0.66) {
        addScore = 2;
      }

      setState(() {
        score += addScore;
        combo += 1;
        if (isLeft) {
          leftFeedback = "+$addScore! (Combo $combo)";
        } else {
          rightFeedback = "+$addScore! (Combo $combo)";
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
          } else {
            rightWord = null;
          }
        });
        _nextQuestion(isLeft: isLeft);
      });
    } else {
      _playSE('wrong');
      _recordMistake(targetWord);

      setState(() {
        combo = 0;
        if (isLeft) {
          leftDisabledChoices.add(selectedChoice);
          leftMistaken = true;
        } else {
          rightDisabledChoices.add(selectedChoice);
          rightMistaken = true;
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
      remainingTime = max(0, remainingTime - 3.0);
      if (isLeft) {
        leftFeedback = "タイムオーバー! (-3秒)";
      } else {
        rightFeedback = "タイムオーバー! (-3秒)";
      }
    });

    questionQueue.add(targetWord);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || isGameOver || !isGameStarted) return;
      setState(() {
        if (isLeft) {
          leftWord = null;
        } else {
          rightWord = null;
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
    setState(() {
      isGameStarted = false;
      isGameOver = false;
      isPaused = false;
      leftWord = null;
      rightWord = null;
    });
    widget.onGameStateChanged?.call(false);
  }

  void _endGame() {
    _resetAndStopAll();
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

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('2レーン英単語クイズ'),
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
        child: !isGameStarted
            ? _buildStartScreen()
            : Column(
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
                            color: remainingTime <= 10
                                ? Colors.red
                                : Colors.black,
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
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '難易度を選択してください',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('初級')),
                ButtonSegment(value: 2, label: Text('中級')),
                ButtonSegment(value: 3, label: Text('上級')),
              ],
              selected: {selectedLevel},
              onSelectionChanged: (newSelection) {
                setState(() {
                  selectedLevel = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 18,
                ),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _startGame,
              child: const Text(
                'ゲームスタート',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
                setState(() {
                  isGameStarted = false;
                });
                widget.onGameStateChanged?.call(false);
              },
              child: const Text(
                'スタート画面へ戻る',
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
                            color: Colors.black.withValues(alpha: 0.72),
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
              children: List.generate(choices.length, (index) {
                final choice = choices[index];
                final isDisabled = disabledChoices.contains(choice);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.red.shade100,
                        disabledForegroundColor: Colors.red.shade700,
                        backgroundColor: isDisabled
                            ? Colors.red.shade100
                            : Colors.grey[100],
                        foregroundColor: isDisabled
                            ? Colors.red.shade700
                            : Colors.black87,
                        elevation: isDisabled ? 0 : 1,
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
                          decoration: isDisabled
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
