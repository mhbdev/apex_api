import 'package:apex_api/src/notifier/message_notifier.dart';
import 'package:flutter/material.dart';

import 'models/response.dart';

typedef ResType = Response Function(Map<String, dynamic> m);

typedef Json = Map<String, dynamic>;

typedef NotifierWidgetBuilder<T> = Widget Function(BuildContext context, MessageNotifier<T> notifier);

typedef FingerprintCallback = Future<String> Function();

typedef EventHandler<T> = void Function(T data);