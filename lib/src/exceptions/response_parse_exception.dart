import 'constants.dart';
import 'server_exception.dart';

class ResponseParseException extends ServerException {
  ResponseParseException([String? message])
      : super(
          message: message ?? '',
          code: ExceptionConstants.responseParseError,
        );
}
