import 'package:http/http.dart';

class BrowserClient extends BaseClient {
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    throw UnimplementedError();
  }
}