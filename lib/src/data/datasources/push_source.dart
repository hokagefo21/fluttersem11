import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/registration.dart';

class DevicePushSource {
  final FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin _local;
  DevicePushSource(this.messaging, this._local);
  final _events = StreamController<PushNotice>.broadcast(sync: true);
  final _tokens = StreamController<String>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  PushNotice _notice = const PushNotice(PushPhase.initializing);
  String? token;
  Stream<String> get refreshedTokens => _tokens.stream;
  Stream<PushNotice> observe() => Stream.multi((out) {
    out.add(_notice);
    final sub = _events.stream.listen(out.add, onDone: out.close);
    out.onCancel = sub.cancel;
  });
  void publish(PushPhase phase, {String? message}) {
    _notice = _notice.update(phase, body: message);
    if (!_events.isClosed) _events.add(_notice);
  }

  Future<void> initialize() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (_) => publish(
          PushPhase.opened,
          message: 'Открыто уведомление о регистрации',
        ),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'registration',
              'Регистрация',
              description: 'Подтверждение успешной регистрации',
              importance: Importance.high,
            ),
          );
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((m) => unawaited(_foreground(m))),
      );
      _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen(_opened));
      // The existing Admin SDK worker sends to FCM registration tokens.
      _subscriptions.add(
        // ignore: deprecated_member_use
        messaging.onTokenRefresh.listen((value) {
          token = value;
          _tokens.add(value);
        }, onError: (_) => publish(PushPhase.tokenFailed)),
      );
      final initial = await messaging.getInitialMessage();
      await requestToken();
      if (initial != null) _opened(initial);
    } catch (_) {
      publish(PushPhase.unavailable);
    }
  }

  Future<String?> requestToken() async {
    try {
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        token = null;
        publish(PushPhase.denied);
        return null;
      }
      // ignore: deprecated_member_use
      token = await messaging.getToken().timeout(const Duration(seconds: 15));
      publish(token == null ? PushPhase.missingToken : PushPhase.ready);
    } catch (_) {
      token = null;
      publish(PushPhase.unavailable);
    }
    return token;
  }

  void _opened(RemoteMessage m) => publish(
    PushPhase.opened,
    message: m.notification?.body ?? 'Открыто уведомление о регистрации',
  );
  Future<void> _foreground(RemoteMessage m) async {
    final body = m.notification?.body ?? 'Получено push-уведомление';
    publish(PushPhase.received, message: body);
    try {
      await _local.show(
        id: m.messageId.hashCode & 0x7fffffff,
        title: m.notification?.title ?? 'Регистрация',
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'registration',
            'Регистрация',
            channelDescription: 'Подтверждение успешной регистрации',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        payload: m.data['uid'] as String?,
      );
    } catch (_) {
      publish(PushPhase.displayFailed);
    }
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _tokens.close();
    await _events.close();
  }
}
