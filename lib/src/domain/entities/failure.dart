sealed class Failure implements Exception {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class ServerFailure extends Failure {
  const ServerFailure();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

enum InputIssue {
  name,
  email,
  phone,
  password,
  emailInUse,
  emptyDraft,
  invalidRequest,
}

final class ValidationFailure extends Failure {
  final InputIssue issue;
  const ValidationFailure([this.issue = InputIssue.invalidRequest]);
}

final class RateLimitFailure extends Failure {
  const RateLimitFailure();
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure();
}
