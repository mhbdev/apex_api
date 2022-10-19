import 'constants.dart';
import 'server_exception.dart';

class UnauthorisedException extends ServerException {
  UnauthorisedException([String? message])
      : super(
          message: message ?? '',
          code: ExceptionConstants.unauthorized,
        );
}
