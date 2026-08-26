import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dominican_casino/services/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM presentation and notification-tap delivery.
///
/// Some FCM payloads are "data-only". In those cases the OS won't display a
/// banner when the app is backgrounded/killed, so we render a local
/// notification from [firebaseMessagingBackgroundHandler].
///
/// On Android, FCM does not show notification payloads while the app is in
/// the foreground — we mirror iOS by posting a local notification from
/// [FirebaseMessaging.onMessage].
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  bool _configured = false;
  RemoteMessage? _launchMessage;
  final _opened = StreamController<RemoteMessage>.broadcast();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const channelId = 'fcm_game';
  static const channelName = 'Game notifications';

  /// Taps on a notification (cold start after [flushLaunchMessage], and
  /// background via [FirebaseMessaging.onMessageOpenedApp]).
  Stream<RemoteMessage> get opened => _opened.stream;

  /// Android 13+ runtime permission (no-op on older API levels / iOS).
  Future<bool> requestAndroidPostNotificationsPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    developer.log(
      'Android POST_NOTIFICATIONS granted=$granted',
      name: 'notifications',
    );
    return granted ?? true;
  }

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
    // Icon must match flutter_launcher_icons output (`launcher_icon`).
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(settings: init);
    await _ensureAndroidChannel(_local);

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    FirebaseMessaging.onMessage.listen((message) {
      developer.log(
        'FCM foreground title=${message.notification?.title} '
        'data=${message.data}',
        name: 'notifications',
      );
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        unawaited(_showLocalFromRemoteMessage(_local, message));
      }
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

Future<void> _ensureAndroidChannel(FlutterLocalNotificationsPlugin local) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final android = local.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return;
  await android.createNotificationChannel(
    const AndroidNotificationChannel(
      NotificationsService.channelId,
      NotificationsService.channelName,
      description: 'Turn alerts, energy full, and other game updates',
      importance: Importance.max,
    ),
  );
}

Future<void> _showLocalFromRemoteMessage(
  FlutterLocalNotificationsPlugin local,
  RemoteMessage message,
) async {
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
        NotificationsService.channelId,
        NotificationsService.channelName,
        channelDescription: 'Turn alerts, energy full, and other game updates',
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

/// Background handler for FirebaseMessaging.
/// Must be a top-level entry point.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final local = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  const iosInit = DarwinInitializationSettings();
  const init = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await local.initialize(settings: init);
  await _ensureAndroidChannel(local);
  await _showLocalFromRemoteMessage(local, message);
}
