import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/failure.dart';
import '../../domain/entities/registration.dart';
import '../../domain/usecases/registration_actions.dart';

sealed class ViewState<T> {
  const ViewState();
}

final class Empty<T> extends ViewState<T> {
  const Empty();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Success<T> extends ViewState<T> {
  final T value;
  const Success(this.value);
}

final class ErrorState<T> extends ViewState<T> {
  final Failure failure;
  const ErrorState(this.failure);
}

class RegistrationState {
  final ViewState<RegisteredProfile> registration;
  final ViewState<ContactDraft> draft;
  final PushNotice push;
  final Failure? actionError;
  final bool working;
  const RegistrationState({
    this.registration = const Empty(),
    this.draft = const Loading(),
    this.push = const PushNotice(PushPhase.initializing),
    this.actionError,
    this.working = false,
  });
  bool get busy => working || registration is Loading || draft is Loading;
  RegistrationState copy({
    ViewState<RegisteredProfile>? registration,
    ViewState<ContactDraft>? draft,
    PushNotice? push,
    Failure? error,
    bool clearError = false,
    bool? working,
  }) => RegistrationState(
    registration: registration ?? this.registration,
    draft: draft ?? this.draft,
    push: push ?? this.push,
    actionError: clearError ? null : error ?? actionError,
    working: working ?? this.working,
  );
}

class RegistrationCubit extends Cubit<RegistrationState> {
  final RegisterAccount register;
  final StartNewRegistration startNew;
  final RequestNotifications request;
  final LoadDraft load;
  final SaveDraft save;
  final ClearDraft clear;
  late final StreamSubscription<PushNotice> _events;
  RegistrationCubit(
    this.register,
    this.startNew,
    ObserveNotifications observe,
    this.request,
    this.load,
    this.save,
    this.clear,
  ) : super(const RegistrationState()) {
    _events = observe().listen(
      (event) => _update(state.copy(push: event)),
      onError: (Object e) => _update(state.copy(error: _failure(e))),
    );
    unawaited(_readDraft());
  }
  Failure _failure(Object e) => e is Failure ? e : const UnknownFailure();
  void _update(RegistrationState next) {
    if (!isClosed) emit(next);
  }

  Future<void> _readDraft() async {
    try {
      final data = await load();
      _update(state.copy(draft: data == null ? const Empty() : Success(data)));
    } catch (e) {
      _update(state.copy(draft: ErrorState(_failure(e))));
    }
  }

  Future<void> reloadDraft() async {
    if (state.busy) return;
    _update(state.copy(draft: const Loading(), clearError: true));
    await _readDraft();
  }

  Future<void> storeDraft(ContactDraft data) => _action(() async {
    await save(data);
    await _readDraft();
  });
  Future<void> removeDraft() => _action(() async {
    await clear();
    _update(state.copy(draft: const Empty()));
  });
  Future<void> submit(ContactDraft contact, String password) async {
    if (state.busy || state.registration is Success) return;
    _update(state.copy(registration: const Loading(), clearError: true));
    try {
      final profile = await register(contact, password);
      // A local cleanup failure must never turn a confirmed cloud write into a failed registration.
      try {
        await clear();
        _update(
          state.copy(registration: Success(profile), draft: const Empty()),
        );
      } catch (e) {
        _update(
          state.copy(
            registration: Success(profile),
            draft: ErrorState(_failure(e)),
          ),
        );
      }
    } catch (e) {
      _update(state.copy(registration: ErrorState(_failure(e))));
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (state.busy) return;
    _update(state.copy(working: true, clearError: true));
    try {
      await action();
    } catch (e) {
      _update(state.copy(error: _failure(e)));
    } finally {
      _update(state.copy(working: false));
    }
  }

  Future<void> retryPush() => _action(request.call);
  Future<void> reset() => _action(() async {
    await startNew();
    _update(state.copy(registration: const Empty()));
  });
  @override
  Future<void> close() async {
    await _events.cancel();
    await super.close();
  }
}
