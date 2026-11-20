import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/domain/entities/failure.dart';
import 'package:untitled/src/presentation/pages/registration_page.dart';

import 'fakes.dart';

Future<void> mount(
  WidgetTester tester,
  FakeAccount account,
  MemoryDraft drafts,
) async {
  final cubit = makeCubit(account, drafts);
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: cubit, child: const RegistrationPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester t, String text) async {
  final button = find.text(text);
  await t.ensureVisible(button);
  await t.tap(button);
  await t.pump();
}

Future<void> fill(WidgetTester t) async {
  final fields = find.byType(TextFormField);
  for (final (i, s) in [
    'Student',
    'student@example.org',
    '+77001234567',
    'SamplePass11',
  ].indexed) {
    await t.enterText(fields.at(i), s);
  }
}

void main() {
  testWidgets('Invalid form never sends a request', (t) async {
    final a = FakeAccount();
    await mount(t, a, MemoryDraft());
    await tap(t, 'Зарегистрироваться');
    expect(a.calls, 0);
    expect(find.text('Введите корректный email'), findsOneWidget);
  });
  testWidgets(
    'Confirmation waits for persistence and blocks duplicate requests',
    (t) async {
      final a = FakeAccount()..pending = Completer<void>();
      await mount(t, a, MemoryDraft());
      await fill(t);
      await tap(t, 'Зарегистрироваться');
      expect(a.calls, 1);
      expect(find.text('Регистрация успешна'), findsNothing);
      expect(
        t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      a.pending!.complete();
      await t.pumpAndSettle();
      expect(find.text('Регистрация успешна'), findsOneWidget);
      expect(a.submitted!.email, 'student@example.org');
    },
  );
  testWidgets('Failure is readable and retry succeeds', (t) async {
    final a = FakeAccount()..failure = const NetworkFailure();
    await mount(t, a, MemoryDraft());
    await fill(t);
    await tap(t, 'Зарегистрироваться');
    await t.pumpAndSettle();
    expect(find.textContaining('Нет связи с сервером'), findsOneWidget);
    a.failure = null;
    await tap(t, 'Зарегистрироваться');
    await t.pumpAndSettle();
    expect(a.calls, 2);
    expect(find.text('Регистрация успешна'), findsOneWidget);
  });
  testWidgets(
    'Saved contact can be restored or cleared without restoring a password',
    (t) async {
      final drafts = MemoryDraft()..data = validContact.normalized;
      await mount(t, FakeAccount(), drafts);
      await tap(t, 'Восстановить');
      final fields = t
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields[1].controller!.text, 'student@example.org');
      expect(fields[3].controller!.text, isEmpty);
      await tap(t, 'Удалить черновик');
      await t.pumpAndSettle();
      expect(find.text('Сохранённого черновика нет.'), findsOneWidget);
    },
  );
}
