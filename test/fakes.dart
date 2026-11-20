import 'dart:async';

import 'package:untitled/src/domain/entities/failure.dart';
import 'package:untitled/src/domain/entities/registration.dart';
import 'package:untitled/src/domain/repositories/contracts.dart';
import 'package:untitled/src/domain/usecases/registration_actions.dart';
import 'package:untitled/src/presentation/bloc/registration_cubit.dart';

class FakeAccount implements RegistrationRepository, NotificationRepository {
  int calls = 0, requests = 0;
  ContactDraft? submitted;
  Failure? failure;
  Completer<void>? pending;
  @override
  Future<RegisteredProfile> register(
    ContactDraft draft,
    String password,
  ) async {
    calls++;
    submitted = draft;
    if (failure case final f?) throw f;
    await pending?.future;
    return RegisteredProfile('uid-1', draft);
  }

  @override
  Future<void> signOut() async {}
  @override
  Stream<PushNotice> observe() =>
      Stream.value(const PushNotice(PushPhase.ready));
  @override
  Future<void> request() async {
    requests++;
  }
}

class MemoryDraft implements DraftRepository {
  ContactDraft? data;
  bool failRead = false, failClear = false;
  int reads = 0;
  @override
  Future<ContactDraft?> read() async {
    reads++;
    if (failRead) throw const StorageFailure();
    return data;
  }

  @override
  Future<void> save(ContactDraft draft) async {
    data = draft;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw const StorageFailure();
    data = null;
  }
}

RegistrationCubit makeCubit(FakeAccount account, MemoryDraft drafts) =>
    RegistrationCubit(
      RegisterAccount(account),
      StartNewRegistration(account),
      ObserveNotifications(account),
      RequestNotifications(account),
      LoadDraft(drafts),
      SaveDraft(drafts),
      ClearDraft(drafts),
    );
const validContact = ContactDraft(
  name: ' Student ',
  email: ' Student@Example.org ',
  phone: '+77001234567',
);
