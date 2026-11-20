import '../../domain/entities/registration.dart';
import '../../domain/repositories/contracts.dart';
import '../datasources/local_draft_source.dart';
import '../datasources/registration_remote_source.dart';
import '../mapper/contact_mapper.dart';
import '../mapper/failure_mapper.dart';

class FirebaseAccountRepository
    implements RegistrationRepository, NotificationRepository {
  final RegistrationRemoteSource source;
  FirebaseAccountRepository(this.source);
  @override
  Future<RegisteredProfile> register(ContactDraft contact, String password) =>
      guarded(
        () async =>
            (await source.register(contact.toDto(), password)).toEntity(),
      );
  @override
  Future<void> signOut() => guarded(source.signOut);
  @override
  Future<void> request() => guarded(source.requestPush);
  @override
  Stream<PushNotice> observe() async* {
    try {
      yield* source.observe();
    } catch (e) {
      throw mapFailure(e);
    }
  }
}

class PersistentDraftRepository implements DraftRepository {
  final LocalDraftSource source;
  PersistentDraftRepository(this.source);
  @override
  Future<ContactDraft?> read() =>
      guarded(() async => (await source.read())?.toEntity());
  @override
  Future<void> save(ContactDraft data) =>
      guarded(() => source.write(data.toDto()));
  @override
  Future<void> clear() => guarded(source.clear);
}
