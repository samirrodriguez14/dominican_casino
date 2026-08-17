import 'dart:developer' as developer;

import 'package:dominican_casino/app.dart';
import 'package:dominican_casino/services/firebase_options.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/felt_walnut_theme.dart';
import 'package:dominican_casino/view_models/app_theme_view_model.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:dominican_casino/view_models/home_view_model.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  AppStyle.theme = FeltWalnutTheme();

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
