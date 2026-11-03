/// App Store screenshot tour. Off unless started via [main_store_shots.dart].
///
/// Do **not** use `--dart-define=STORE_SCREENSHOTS=true` — Flutter writes that
/// into `ios/Flutter/Generated.xcconfig` and every later Xcode/flutter run
/// keeps auto-creating Sweep → Tres y Dos → Rummy local games.
bool kStoreScreenshots = false;

/// Call only from `lib/main_store_shots.dart` before [main].
void enableStoreScreenshots() {
  kStoreScreenshots = true;
}
