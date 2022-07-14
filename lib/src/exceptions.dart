enum RetryReason { maxRetryReached, responseIsNull, jsonFormatException }

enum ConnectionError {
  /// Response success parameter is not 1
  failed,
  /// Response is null
  nullResponseError,
  /// Response could not be parsed to json
  parseResponseError,
  cancelError,
  connectionError,
  /// Server Response's status code is 500
  internalServerError,
  /// Connectivity check error
  networkError,
  /// User Authentication error if needsCredentials is true
  authenticationError,
  /// Status other than 200
  statusNOK
}

class AuthenticationError implements Exception {
  final String message;

  AuthenticationError(this.message);

  @override
  String toString() {
    return 'AuthenticationError => $message';
  }
}

class NullResponseError implements Exception {
  final String message;

  NullResponseError(this.message);

  @override
  String toString() {
    return 'NullResponseError => $message';
  }
}

class ConnectionException implements Exception {
  final String message;

  ConnectionException(this.message);

  @override
  String toString() {
    return 'Connection error => $message';
  }
}