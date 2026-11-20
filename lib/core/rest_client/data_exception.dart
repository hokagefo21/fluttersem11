import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

sealed class DataException implements Exception {
  const DataException();
  factory DataException.from(Object error) {
    if (error is DataException) return error;
    if (error is SocketException || error is TimeoutException) {
      return const ConnectionException();
    }
    if (error is FirebaseException) return DataException.fromCode(error.code);
    return const UnexpectedDataException();
  }
  factory DataException.fromCode(String code) {
    final key = code.toLowerCase().split('/').last.replaceAll('_', '-');
    final status = int.tryParse(key);
    if (status != null) return ResponseException(status);
    return switch (key) {
      'network-request-failed' ||
      'network-error' ||
      'unavailable' ||
      'disconnected' ||
      'timeout' ||
      'deadline-exceeded' => const ConnectionException(),
      'invalid-email' ||
      'weak-password' ||
      'email-already-in-use' ||
      'invalid-argument' => ResponseException(400, key),
      'unauthenticated' ||
      'permission-denied' ||
      'invalid-user-token' ||
      'user-token-expired' ||
      'operation-not-allowed' => const ResponseException(401),
      'too-many-requests' => const ResponseException(429),
      'internal' ||
      'internal-error' ||
      'unknown-server-error' => const ResponseException(500),
      _ => const UnexpectedDataException(),
    };
  }
}

final class ConnectionException extends DataException {
  const ConnectionException();
}

final class ResponseException extends DataException {
  final int status;
  final String? reason;
  const ResponseException(this.status, [this.reason]);
}

final class LocalDataException extends DataException {
  const LocalDataException();
}

final class UnexpectedDataException extends DataException {
  const UnexpectedDataException();
}
