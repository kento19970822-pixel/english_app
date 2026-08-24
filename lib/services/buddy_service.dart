// コード管理番号: VER-20260824-49
/// 相棒キャラクター管理サービス (F-14)
class BuddyService {
  static final BuddyService instance = BuddyService._internal();
  factory BuddyService() => instance;
  BuddyService._internal();

  int _selectedSpeciesId = 0; // デフォルト: 0 (ヒヨコ)

  int get selectedSpeciesId => _selectedSpeciesId;

  void setSelectedSpeciesId(int id) {
    _selectedSpeciesId = id % 12;
  }
}
