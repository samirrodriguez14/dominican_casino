import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class AppThemeViewModel extends ChangeNotifier {
  final AppRepo _appRepo;
  Theme get appTheme => _appRepo.appTheme;
  AppThemeViewModel({required AppRepo appRepo}): _appRepo = appRepo; 

  void selectTheme(Theme theme) {
    _appRepo.appTheme = theme;
  }

  
}
