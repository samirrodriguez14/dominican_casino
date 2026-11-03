/// App Store screenshot tour. Enable with:
/// `flutter run --dart-define=STORE_SCREENSHOTS=true`
const bool kStoreScreenshots =
    bool.fromEnvironment('STORE_SCREENSHOTS', defaultValue: false);
