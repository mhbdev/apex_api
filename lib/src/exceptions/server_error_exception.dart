import 'constants.dart';
import 'server_exception.dart';

class ServerErrorException extends ServerException {
  ServerErrorException([String? message])
      : super(
          message: message ?? '',
          code: ExceptionConstants.internalServerError,
        );
}
