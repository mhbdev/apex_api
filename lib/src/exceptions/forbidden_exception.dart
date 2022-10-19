import 'constants.dart';
import 'server_exception.dart';

class ForbiddenException extends ServerException {
  ForbiddenException([String? message])
      : super(
          message: message ?? '',
          code: ExceptionConstants.forbidden,
        );
}
