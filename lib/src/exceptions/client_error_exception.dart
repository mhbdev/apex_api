import 'constants.dart';
import 'server_exception.dart';

class ClientErrorException extends ServerException {
  ClientErrorException([String? message])
      : super(
          message: message ?? '',
          code: ExceptionConstants.clientErrorException,
        );
}
