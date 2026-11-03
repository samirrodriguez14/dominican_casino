import 'package:barajando/main.dart' as app;
import 'package:barajando/store_shots/store_shot_flags.dart';

/// Dedicated entry for App Store screenshot capture.
///
/// ```bash
/// flutter run -d <UDID> -t lib/main_store_shots.dart
/// ```
void main() {
  enableStoreScreenshots();
  app.main();
}
