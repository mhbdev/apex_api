import 'constants.dart';
import 'server_exception.dart';

class NetworkErrorException extends ServerException {
  NetworkErrorException([String? message])
      : super(
          message: message ?? '',
          code: ExceptionConstants.networkError,
        );
}
