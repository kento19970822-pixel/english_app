// コード管理番号: VER-20260826-08
import 'package:flutter/foundation.dart';
import '../db/app_database.dart';
import '../widgets/pixel_character_widget.dart';

/// 相棒キャラクター＆お気に入りスタンプ管理サービス (F-14 / Requirement 1 & 8)
class BuddyService extends ChangeNotifier {
  static final BuddyService instance = BuddyService._internal();
  factory BuddyService() => instance;
  BuddyService._internal();

  int _selectedSpeciesId = 0; // デフォルト: 0 (Chapter 1の相棒)
  Stamp? _favoriteStamp;

  int get selectedSpeciesId => _selectedSpeciesId;
  Stamp? get favoriteStamp => _favoriteStamp;

  void setSelectedSpeciesId(int id) {
    _selectedSpeciesId = id % kTotalChapterCount;
    notifyListeners();
  }

  void setFavoriteStamp(Stamp? stamp) {
    _favoriteStamp = stamp;
    notifyListeners();
  }

  /// DBから最新の相棒種族とお気に入りスタンプを読み込んで同期・通知
  Future<void> reloadFromDatabase(AppDatabase db) async {
    final stamp = await db.getFavoriteStamp();
    _favoriteStamp = stamp;
    notifyListeners();
  }
}

