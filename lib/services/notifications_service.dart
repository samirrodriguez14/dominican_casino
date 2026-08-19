import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM presentation and notification-tap delivery.
///
/// Some FCM payloads are "data-only". In those cases the OS won't display a
/// banner when the app is backgrounded/killed, so we render a local
/// notification from [firebaseMessagingBackgroundHandler].
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  bool _configured = false;
  RemoteMessage? _launchMessage;
  final _opened = StreamController<RemoteMessage>.broadcast();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'fcm_game';
  static const _channelName = 'Game notifications';

  /// Taps on a notification (cold start after [flushLaunchMessage], and
  /// background via [FirebaseMessaging.onMessageOpenedApp]).
  Stream<RemoteMessage> get opened => _opened.stream;

  Future<void> configure() async {
    if (_configured) return;
    _configured = true;

    // Allow banners while the app is in the foreground (iOS).
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Initialize local notifications (for backgrounded "data-only" payloads).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(settings: init);

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
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

/// Background handler for FirebaseMessaging.
/// Must be a top-level entry point.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const channelId = NotificationsService._channelId;
  const channelName = NotificationsService._channelName;

  final local = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const init = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await local.initialize(settings: init);

  final title = message.notification?.title ??
      message.data['title']?.toString() ??
      'Dominican Casino';
  final body = message.notification?.body ??
      message.data['body']?.toString() ??
      '';

  if (body.isEmpty && title.isEmpty) return;

  final id = message.messageId?.hashCode ??
      DateTime.now().millisecondsSinceEpoch;
  final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

  await local.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'FCM notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  );
}
