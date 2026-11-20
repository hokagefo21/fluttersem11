import '../entities/registration.dart';

abstract interface class RegistrationRepository {
  Future<RegisteredProfile> register(ContactDraft contact, String password);
  Future<void> signOut();
}

abstract interface class NotificationRepository {
  Stream<PushNotice> observe();
  Future<void> request();
}

abstract interface class DraftRepository {
  Future<ContactDraft?> read();
  Future<void> save(ContactDraft draft);
  Future<void> clear();
}
