import 'models/response.dart';
import 'notifier/message_notifier.dart';

class SocketJoinController<T extends BaseResponse> extends MessageNotifier {
  final String groupName;
  final void Function(T data) _onListen;

  SocketJoinController(this.groupName, this._onListen);

  void close() {
    notifyListeners(groupName);
  }

  void onData(T data) {
    _onListen(data);
  }
}
