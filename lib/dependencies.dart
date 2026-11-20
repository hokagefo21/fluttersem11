import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/data/datasources/push_source.dart';
import 'src/data/datasources/registration_remote_source.dart';
import 'src/data/datasources/local_draft_source.dart';
import 'src/data/mapper/failure_mapper.dart';
import 'src/data/repositories/app_repositories.dart';
import 'src/domain/usecases/registration_actions.dart';
import 'src/presentation/bloc/registration_cubit.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void registerBackgroundHandler() =>
    FirebaseMessaging.onBackgroundMessage(backgroundMessage);

class AppDependencies {
  final FirebaseRegistrationSource remote;
  final RegistrationCubit Function() createCubit;
  AppDependencies(this.remote, this.createCubit);
  Future<void> dispose() => remote.dispose();
}

Future<AppDependencies> configureDependencies() => guarded(() async {
  final app = Firebase.apps.isEmpty
      ? await Firebase.initializeApp()
      : Firebase.app();
  const override = String.fromEnvironment('FIREBASE_DATABASE_URL');
  final url = override.isNotEmpty ? override : app.options.databaseURL;
  if (url == null || url.isEmpty) throw StateError('Missing database URL');
  final push = DevicePushSource(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
  );
  final remote = FirebaseRegistrationSource(
    FirebaseAuth.instanceFor(app: app),
    FirebaseDatabase.instanceFor(app: app, databaseURL: url),
    push,
  );
  final account = FirebaseAccountRepository(remote);
  final drafts = PersistentDraftRepository(
    PreferencesDraftSource(SharedPreferencesAsync()),
  );
  final register = RegisterAccount(account),
      reset = StartNewRegistration(account),
      observe = ObserveNotifications(account),
      request = RequestNotifications(account);
  final load = LoadDraft(drafts),
      save = SaveDraft(drafts),
      clear = ClearDraft(drafts);
  await push.initialize();
  return AppDependencies(
    remote,
    () =>
        RegistrationCubit(register, reset, observe, request, load, save, clear),
  );
});
