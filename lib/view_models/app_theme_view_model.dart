import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/ui/app_shell/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';

class AppThemeViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  Theme get appTheme => _appRepo.appTheme;
  AppThemeViewModel({required this._appRepo});

  void selectTheme(Theme theme) {
    _appRepo.appTheme = theme;
  }

  
}
