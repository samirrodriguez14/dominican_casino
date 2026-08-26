import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Platform-native list scroll feel (bounce on iOS, clamp on Android).
ScrollPhysics platformScrollPhysics([ScrollPhysics? parent]) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return BouncingScrollPhysics(parent: parent);
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return ClampingScrollPhysics(parent: parent);
  }
}
