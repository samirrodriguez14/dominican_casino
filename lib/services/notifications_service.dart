import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM presentation and foreground receive logging.
///
/// iOS hides banners while the app is open unless presentation options
/// are set. Background/killed delivery is handled by the OS from the
/// payload the cloud function sends.
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;
    _configured = true;
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.onMessage.listen((message) {
      developer.log(
        'FCM foreground title=${message.notification?.title} '
        'data=${message.data}',
        name: 'notifications',
      );
    });
  }
}
