import 'constants.dart';
import 'server_exception.dart';

class BadRequestException extends ServerException {
  BadRequestException([String? message])
      : super(
          message: message ?? '',
          code: ExceptionConstants.badRequest,
        );
}
