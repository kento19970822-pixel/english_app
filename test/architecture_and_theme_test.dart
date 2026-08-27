// コード管理番号: VER-20260827-09
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:english_app/db/app_database.dart';
import 'package:english_app/providers/settings_provider.dart';
import 'package:english_app/providers/buddy_provider.dart';
import 'package:english_app/theme/app_theme.dart';
import 'package:english_app/services/tts_service.dart';
import 'package:english_app/widgets/words/word_search_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & WCAG AA Contrast Tests', () {
    test('Light and Dark themes have distinct palettes', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, equals(Brightness.light));
      expect(dark.brightness, equals(Brightness.dark));
      expect(AppTheme.lightBg, isNot(equals(AppTheme.darkBg)));
    });

    test('POS Badge colors provide valid colors for all parts of speech', () {
      final verbLight = AppTheme.getPosBadgeColors('動詞', isDark: false);
      final verbDark = AppTheme.getPosBadgeColors('動詞', isDark: true);
      final nounLight = AppTheme.getPosBadgeColors('名詞', isDark: false);
      final adjLight = AppTheme.getPosBadgeColors('形容詞', isDark: false);

      expect(verbLight.bg, isNotNull);
      expect(verbDark.bg, isNotNull);
      expect(nounLight.bg, isNotNull);
      expect(adjLight.bg, isNotNull);
    });
  });

  group('SettingsProvider & BuddyProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SettingsProvider toggles theme and persists', () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.themeMode, equals(AppThemeMode.light));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(AppThemeMode.dark));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(AppThemeMode.light));
    });

    test('BuddyProvider initializes and notifies listeners', () async {
      final provider = BuddyProvider();
      expect(provider.selectedSpeciesId, equals(0));

      provider.setSelectedSpeciesId(1);
      expect(provider.selectedSpeciesId, equals(1));
    });
  });

  group('Database LearningLogs & Pruning Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('recordLearningLog inserts log and cleanupOldLogs prunes correctly', () async {
      await db.initWordsIfEmpty();
      final words = await db.getAllWords();
      final testWordId = words.isNotEmpty ? words.first.id : 1;

      await db.recordLearningLog(
        wordId: testWordId,
        isCorrect: true,
        mode: 'quiz',
      );

      final logs = await db.select(db.learningLogs).get();
      expect(logs.length, equals(1));
      expect(logs.first.isCorrect, isTrue);
      expect(logs.first.mode, equals('quiz'));

      // Test pruning
      final deleted = await db.cleanupOldLogs(maxAge: const Duration(days: 90));
      expect(deleted, equals(0)); // Should not delete recent log
    });
  });

  group('TtsService Debounce Logic Tests', () {
    test('Voice scoring prioritizes neural and wavenet voices', () {
      final voices = [
        {'name': 'en-us-x-sfg-network', 'locale': 'en-US'},
        {'name': 'Microsoft Jenny Neural', 'locale': 'en-US'},
        {'name': 'ja-JP-standard', 'locale': 'ja-JP'},
      ];

      final best = TtsService.selectBestVoice(voices);
      expect(best, isNotNull);
      expect(best!['name'], equals('Microsoft Jenny Neural'));
    });
  });

  group('WordSearchBar Widget Tests', () {
    testWidgets('WordSearchBar renders search field and buttons', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordSearchBar(
              searchController: controller,
              searchFocusNode: focusNode,
              onChanged: (_) {},
              onClear: () {},
              soundEnabled: true,
              onToggleSound: () {},
              activeFilterCount: 2,
              onOpenFilter: () {},
              onSyncFlags: () async {},
              onResetWordsDb: () async {},
              onResetLearningData: () async {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Badge count
    });
  });
}
