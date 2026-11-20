import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/core/rest_client/data_exception.dart';
import 'package:untitled/models/contact_dto.dart';
import 'package:untitled/src/data/datasources/local_draft_source.dart';
import 'package:untitled/src/data/mapper/failure_mapper.dart';
import 'package:untitled/src/data/repositories/app_repositories.dart';
import 'package:untitled/src/domain/entities/failure.dart';
import 'package:untitled/src/domain/entities/registration.dart';
import 'package:untitled/src/domain/usecases/registration_actions.dart';
import 'package:untitled/src/presentation/bloc/registration_cubit.dart';

import 'fakes.dart';

class RecordingSource implements LocalDraftSource {
  ContactDto? data;
  @override
  Future<ContactDto?> read() async => data;
  @override
  Future<void> write(ContactDto dto) async {
    data = dto;
  }

  @override
  Future<void> clear() async {
    data = null;
  }
}

void main() {
  for (final (code, type) in [
    ('network-request-failed', NetworkFailure),
    ('internal-error', ServerFailure),
    ('500', ServerFailure),
    ('401', UnauthorizedFailure),
    ('database/permission-denied', UnauthorizedFailure),
    ('400', ValidationFailure),
    ('email-already-in-use', ValidationFailure),
    ('weird-private-detail', UnknownFailure),
  ]) {
    test(
      'Maps $code to $type',
      () => expect(
        mapFailure(FirebaseException(plugin: 'test', code: code)).runtimeType,
        type,
      ),
    );
  }
  test('Timeout and socket errors use network failure', () {
    expect(mapFailure(TimeoutException('private')), isA<NetworkFailure>());
    expect(mapFailure(const SocketException('private')), isA<NetworkFailure>());
  });
  test('Invalid contact is rejected in the domain before any write', () async {
    final a = FakeAccount();
    await expectLater(
      RegisterAccount(a)(
        const ContactDraft(name: '', email: '?', phone: '123'),
        'short',
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(a.calls, 0);
  });
  test(
    'Draft repository maps persisted data and contains only contact fields',
    () async {
      final src = RecordingSource(), repo = PersistentDraftRepository(src);
      await SaveDraft(repo)(validContact);
      expect(
        src.data!.toJson().keys,
        unorderedEquals(['name', 'email', 'phone']),
      );
      expect(
        (await LoadDraft(PersistentDraftRepository(src))())!.email,
        'student@example.org',
      );
      await ClearDraft(repo)();
      expect(await LoadDraft(repo)(), isNull);
    },
  );
  test('Empty draft is rejected while partial input can be saved', () async {
    final r = MemoryDraft();
    await expectLater(
      SaveDraft(r)(const ContactDraft(name: ' ', email: '', phone: '')),
      throwsA(isA<ValidationFailure>()),
    );
    await SaveDraft(r)(const ContactDraft(name: 'A', email: '', phone: ''));
    expect(r.data!.name, 'A');
  });
  test('Late send acknowledgement preserves receipt', () {
    final receipt = const PushNotice(PushPhase.ready)
        .update(PushPhase.received, body: 'Welcome');
    expect(receipt.update(PushPhase.sent).phase, PushPhase.received);
  });
  test('Local failure can be retried and empty state is explicit', () async {
    final r = MemoryDraft()..failRead = true;
    final c = makeCubit(FakeAccount(), r);
    addTearDown(c.close);
    await Future<void>.delayed(Duration.zero);
    expect(c.state.draft, isA<ErrorState<ContactDraft>>());
    r.failRead = false;
    await c.reloadDraft();
    expect(c.state.draft, isA<Empty<ContactDraft>>());
    expect(r.reads, 2);
  });
  test(
    'Concurrent submit writes only once, cleanup failure preserves receipt',
    () async {
      final a = FakeAccount()..pending = Completer<void>(),
          r = MemoryDraft()..failClear = true;
      final c = makeCubit(a, r);
      addTearDown(c.close);
      await Future<void>.delayed(Duration.zero);
      final first = c.submit(validContact, 'SamplePass11');
      await c.submit(validContact, 'SamplePass11');
      expect(a.calls, 1);
      a.pending!.complete();
      await first;
      expect(c.state.registration, isA<Success<RegisteredProfile>>());
      expect(c.state.draft, isA<ErrorState<ContactDraft>>());
      r.failClear = false;
      await c.removeDraft();
      expect(c.state.draft, isA<Empty<ContactDraft>>());
    },
  );
  test('Technical exception details are not exposed by repositories', () async {
    await expectLater(
      guarded<void>(() async {
        throw const UnexpectedDataException();
      }),
      throwsA(isA<UnknownFailure>()),
    );
  });
  test('Layer imports point inward', () {
    for (final layer in ['domain', 'presentation']) {
      for (final file
          in Directory('lib/src/$layer')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        for (final line in file.readAsLinesSync().where(
          (s) => s.startsWith('import '),
        )) {
          expect(
            line,
            isNot(
              matches(
                RegExp(
                  r'firebase_|shared_preferences|/data/|/models/|core/rest_client|dependencies\.dart',
                ),
              ),
            ),
            reason: file.path,
          );
          if (layer == 'domain') {
            expect(line, isNot(contains('package:')), reason: file.path);
            expect(line, isNot(contains('presentation/')), reason: file.path);
          }
        }
      }
    }
  });
}
