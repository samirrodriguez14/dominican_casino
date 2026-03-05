import 'dart:developer' as devloper;

import 'package:dominican_casino/app.dart';
import 'package:dominican_casino/firebase_options.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/repositories/game_repo.dart';
import 'package:dominican_casino/services/firestore_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/casino_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

void main() async {
  AppStyle.theme = CasinoTheme();

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    devloper.log("Eror initializing Firebase");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (context) => FirestoreService()),
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
      ],

      child: App(),
    ),
  );
}
