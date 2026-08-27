// コード管理番号: VER-20260827-03
import 'package:flutter/material.dart';
import '../services/buddy_service.dart';
import '../db/app_database.dart';

/// 相棒キャラクター状態管理プロバイダー
class BuddyProvider extends ChangeNotifier {
  final BuddyService _service = BuddyService.instance;

  BuddyProvider() {
    _service.addListener(_onBuddyServiceChanged);
  }

  void _onBuddyServiceChanged() {
    notifyListeners();
  }

  int get selectedSpeciesId => _service.selectedSpeciesId;
  Stamp? get favoriteStamp => _service.favoriteStamp;

  void setSelectedSpeciesId(int id) {
    _service.setSelectedSpeciesId(id);
    notifyListeners();
  }

  void setFavoriteStamp(Stamp? stamp) {
    _service.setFavoriteStamp(stamp);
    notifyListeners();
  }

  Future<void> reloadFromDatabase(AppDatabase db) async {
    await _service.reloadFromDatabase(db);
    notifyListeners();
  }

  @override
  void dispose() {
    _service.removeListener(_onBuddyServiceChanged);
    super.dispose();
  }
}
