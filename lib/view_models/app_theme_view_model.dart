import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class AppThemeViewModel extends ChangeNotifier {
  AppThemeViewModel({required AppRepo appRepo}) : _appRepo = appRepo;

  final AppRepo _appRepo;

  Theme get appTheme => _appRepo.appTheme;
  CardBackMark get cardBackMark => _appRepo.cardBackMark;
  String get cardBackTintId => _appRepo.cardBackTintId;
  Set<Theme> get ownedPacks => _appRepo.ownedPacks;

  bool ownsPack(Theme id) => _appRepo.ownsPack(id);

  Future<void> equipPack(Theme theme, {String? avatarId}) async {
    await _appRepo.equipPack(theme, avatarId: avatarId);
    notifyListeners();
  }

  Future<bool> buyPack(Theme theme) async {
    final ok = await _appRepo.buyThemePack(theme);
    notifyListeners();
    return ok;
  }

  void setCardBackMark(CardBackMark mark) {
    _appRepo.cardBackMark = mark;
    notifyListeners();
  }

  void setCardBackTintId(String id) {
    _appRepo.cardBackTintId = id;
    notifyListeners();
  }
}
