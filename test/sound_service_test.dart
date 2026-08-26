// コード管理番号: VER-20260826-09
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_app/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'se_enabled': true});
    });

    test('SoundService singleton instance exists and defaults to enabled', () {
      final service = SoundService.instance;
      expect(service, isNotNull);
      expect(service.isSeEnabled, isTrue);
    });

    test('setSeEnabled updates isSeEnabled and notifies listeners', () async {
      final service = SoundService.instance;
      bool notified = false;
      service.addListener(() {
        notified = true;
      });

      await service.setSeEnabled(false);
      expect(service.isSeEnabled, isFalse);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('se_enabled'), isFalse);

      // Restore to true
      await service.setSeEnabled(true);
      expect(service.isSeEnabled, isTrue);
    });
  });
}
