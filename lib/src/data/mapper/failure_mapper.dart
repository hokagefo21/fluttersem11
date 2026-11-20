import '../../../core/rest_client/data_exception.dart';
import '../../domain/entities/failure.dart';

Failure mapFailure(Object error) {
  if (error is Failure) return error;
  return switch (DataException.from(error)) {
    ConnectionException() => const NetworkFailure(),
    LocalDataException() => const StorageFailure(),
    ResponseException(status: 401 || 403) => const UnauthorizedFailure(),
    ResponseException(status: 429) => const RateLimitFailure(),
    ResponseException(status: >= 500 && < 600) => const ServerFailure(),
    ResponseException(status: 400, reason: final reason) => ValidationFailure(
      switch (reason) {
        'email-already-in-use' => InputIssue.emailInUse,
        'invalid-email' => InputIssue.email,
        'weak-password' => InputIssue.password,
        _ => InputIssue.invalidRequest,
      },
    ),
    _ => const UnknownFailure(),
  };
}

Future<T> guarded<T>(Future<T> Function() run) async {
  try {
    return await run();
  } catch (error) {
    throw mapFailure(error);
  }
}
