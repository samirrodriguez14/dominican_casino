import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM presentation and notification-tap delivery.
///
/// iOS hides banners while the app is open unless presentation options
/// are set. Background/killed delivery is handled by the OS from the
/// payload the cloud function sends. Taps are exposed via [opened].
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  bool _configured = false;
  RemoteMessage? _launchMessage;
  final _opened = StreamController<RemoteMessage>.broadcast();

  /// Taps on a notification (cold start after [flushLaunchMessage], and
  /// background via [FirebaseMessaging.onMessageOpenedApp]).
  Stream<RemoteMessage> get opened => _opened.stream;

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
    FirebaseMessaging.onMessageOpenedApp.listen(_emitOpened);
    try {
      _launchMessage = await FirebaseMessaging.instance.getInitialMessage();
    } catch (e, st) {
      developer.log(
        'FCM: Failed to read launch notification',
        error: e,
        stackTrace: st,
        name: 'notifications',
      );
    }
  }

  /// Deliver the notification that launched a cold start, if any.
  /// Call after subscribing to [opened].
  void flushLaunchMessage() {
    final message = _launchMessage;
    _launchMessage = null;
    if (message != null) _emitOpened(message);
  }

  void _emitOpened(RemoteMessage message) {
    developer.log(
      'FCM opened title=${message.notification?.title} data=${message.data}',
      name: 'notifications',
    );
    _opened.add(message);
  }
}
