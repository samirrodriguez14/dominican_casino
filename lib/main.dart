import 'dart:developer' as developer;

import 'package:youareup/app.dart';
import 'package:youareup/services/firebase_options.dart';
import 'package:youareup/repositories/app_repo.dart';
import 'package:youareup/repositories/game_repo.dart';
import 'package:youareup/services/firestore_service.dart';
import 'package:youareup/services/sound_service.dart';
import 'package:youareup/style/app_theme.dart';
import 'package:youareup/style/sage_theme.dart';
import 'package:youareup/view_models/app_theme_view_model.dart';
import 'package:youareup/view_models/games_view_model.dart';
import 'package:youareup/view_models/home_view_model.dart';
import 'package:youareup/view_models/profile_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  AppStyle.theme = SageTheme();

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    developer.log("Error initializing Firebase");
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SoundService.instance.load();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (context) => FirestoreService()),
        ChangeNotifierProvider<SoundService>.value(
          value: SoundService.instance,
        ),
        ChangeNotifierProvider(
          create: (context) => GameRepo(fs: context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final appRepo = AppRepo(fs: context.read<FirestoreService>());
            appRepo.loadApp();
            return appRepo;
          },
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProfileViewModel(appRepo: context.read<AppRepo>()),
        ),
        ChangeNotifierProvider(
          create: (context) => GamesViewModel(appRepo: context.read<AppRepo>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(appRepo: context.read<AppRepo>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AppThemeViewModel(appRepo: context.read<AppRepo>()),
        ),
      ],
      child: App(),
    ),
  );
}
