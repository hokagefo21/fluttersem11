import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../constants/firebase_paths.dart';
import '../../../core/rest_client/data_exception.dart';
import '../../../models/contact_dto.dart';
import '../../domain/entities/registration.dart';
import 'push_source.dart';

abstract interface class RegistrationRemoteSource {
  Future<ProfileDto> register(ContactDto contact, String password);
  Future<void> signOut();
  Future<void> requestPush();
  Stream<PushNotice> observe();
}

class FirebaseRegistrationSource implements RegistrationRemoteSource {
  final FirebaseAuth auth;
  final FirebaseDatabase db;
  final DevicePushSource push;
  static const timeout = Duration(seconds: 20);
  StreamSubscription<DatabaseEvent>? _delivery;
  late final StreamSubscription<String> _tokenUpdates;
  String? _savedUid;
  Future<void>? _pending;
  (String, String, String, String)? _pendingKey;
  FirebaseRegistrationSource(this.auth, this.db, this.push) {
    _tokenUpdates = push.refreshedTokens.listen(
      (t) => unawaited(_refreshToken(t)),
    );
  }

  @override
  Future<ProfileDto> register(ContactDto contact, String password) async {
    var user = auth.currentUser;
    if (user != null && user.email?.toLowerCase() != contact.email) {
      await signOut();
      user = null;
    }
    user ??= (await auth.createUserWithEmailAndPassword(
      email: contact.email,
      password: password,
    )).user;
    if (user == null) throw const ResponseException(401);
    final uid = user.uid,
        key = (uid, contact.name, contact.email, contact.phone);
    final previous = _pending;
    if (previous != null && _pendingKey != key) {
      await previous.timeout(timeout);
    }
    if (_pending == null) {
      push.publish(
        push.token == null ? PushPhase.missingToken : PushPhase.waiting,
        message: '',
      );
      _pendingKey = key;
      _pending = _write(uid, contact).whenComplete(() {
        _pending = null;
        _pendingKey = null;
      });
    }
    await _pending!.timeout(timeout);
    _savedUid = uid;
    await _delivery?.cancel();
    _delivery = db.ref('$deliveryPath/$uid').onValue.listen((event) {
      if (_savedUid != uid) return;
      final state = event.snapshot.child('status').value;
      if (state == 'sent') {
        push.publish(PushPhase.sent);
      }
      if (state == 'error') {
        push.publish(PushPhase.sendFailed);
      }
    }, onError: (_) => push.publish(PushPhase.statusFailed));
    return ProfileDto(uid, contact);
  }

  Future<void> _write(String uid, ContactDto data) async {
    final ref = db.ref('$usersPath/$uid');
    final old = await ref.get().timeout(timeout);
    await ref.set({
      ...data.toJson(),
      'createdAt': old.child('createdAt').value ?? ServerValue.timestamp,
      'pushRequestedAt': ServerValue.timestamp,
      'fcmToken': push.token,
    });
  }

  Future<void> _update(String token) async {
    final uid = _savedUid;
    if (uid == null) return;
    await db
        .ref('$usersPath/$uid')
        .update({'fcmToken': token, 'pushRequestedAt': ServerValue.timestamp})
        .timeout(timeout);
    if (_savedUid == uid) push.publish(PushPhase.requested);
  }

  Future<void> _refreshToken(String token) async {
    try {
      await _update(token);
    } catch (_) {
      push.publish(PushPhase.tokenFailed);
    }
  }

  @override
  Stream<PushNotice> observe() => push.observe();
  @override
  Future<void> requestPush() async {
    push.publish(PushPhase.initializing, message: '');
    final token = await push.requestToken();
    if (token != null) await _update(token);
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
    _savedUid = null;
    await _delivery?.cancel();
    _delivery = null;
    push.publish(
      push.token == null ? PushPhase.missingToken : PushPhase.ready,
      message: '',
    );
  }

  Future<void> dispose() async {
    await _delivery?.cancel();
    await _tokenUpdates.cancel();
    await push.dispose();
  }
}
