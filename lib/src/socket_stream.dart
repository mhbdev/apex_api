import 'dart:async';

import 'package:flutter/foundation.dart';

class StreamSocket<T> extends ChangeNotifier {
  final _socketResponse = StreamController<T?>.broadcast(sync: true);

  StreamController<T?> get controller => _socketResponse;

  void addResponse(T? data) {
    if(data != null) {
      if (!_socketResponse.isClosed &&
          !_socketResponse.isPaused &&
          _socketResponse.hasListener) {
        _socketResponse.sink.add(data);
      }
    } else {
      _socketResponse.sink.add(data);
    }
  }

  Stream<T?> get getResponse => _socketResponse.stream;

  void close() async {
    if (!_socketResponse.isClosed) {
      notifyListeners();
      await _socketResponse.close();
      // if(!hasListeners) {
      //   dispose();
      // }
    }
  }
}
