class ServerException implements Exception {
  final String code;
  final String message;

  ServerException({required this.message, required this.code});
}
