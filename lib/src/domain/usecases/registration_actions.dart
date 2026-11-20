import '../entities/failure.dart';
import '../entities/registration.dart';
import '../repositories/contracts.dart';

class RegisterAccount {
  final RegistrationRepository repository;
  const RegisterAccount(this.repository);
  static InputIssue? nameIssue(String value) =>
      value.trim().length < 2 || value.trim().length > 100
      ? InputIssue.name
      : null;
  static InputIssue? emailIssue(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? null
      : InputIssue.email;
  static InputIssue? phoneIssue(String value) =>
      RegExp(r'^\+?[0-9 ()-]{10,20}$').hasMatch(value.trim()) &&
          value.trim().length <= 20
      ? null
      : InputIssue.phone;
  static InputIssue? passwordIssue(String value) =>
      value.length < 8 ? InputIssue.password : null;
  Future<RegisteredProfile> call(ContactDraft input, String password) async {
    final data = input.normalized;
    final issue =
        nameIssue(data.name) ??
        emailIssue(data.email) ??
        phoneIssue(data.phone) ??
        passwordIssue(password);
    if (issue != null) throw ValidationFailure(issue);
    return repository.register(data, password);
  }
}

class StartNewRegistration {
  final RegistrationRepository repository;
  const StartNewRegistration(this.repository);
  Future<void> call() => repository.signOut();
}

class ObserveNotifications {
  final NotificationRepository repository;
  const ObserveNotifications(this.repository);
  Stream<PushNotice> call() => repository.observe();
}

class RequestNotifications {
  final NotificationRepository repository;
  const RequestNotifications(this.repository);
  Future<void> call() => repository.request();
}

class LoadDraft {
  final DraftRepository repository;
  const LoadDraft(this.repository);
  Future<ContactDraft?> call() => repository.read();
}

class SaveDraft {
  final DraftRepository repository;
  const SaveDraft(this.repository);
  Future<void> call(ContactDraft draft) async {
    if (draft.isEmpty) throw const ValidationFailure(InputIssue.emptyDraft);
    await repository.save(draft.normalized);
  }
}

class ClearDraft {
  final DraftRepository repository;
  const ClearDraft(this.repository);
  Future<void> call() => repository.clear();
}
