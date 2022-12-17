import 'dart:async';

import 'package:apex_api/src/exceptions/server_exception.dart';
import 'package:apex_api/src/models/request.dart';
import 'package:apex_api/src/notifier/message_notifier.dart';
import 'package:flutter/material.dart';

import 'models/response.dart';

typedef ResType = Response Function(Json m);

typedef ReqType = Request Function(Json m);

typedef Json = Map<String, dynamic>;

typedef NotifierWidgetBuilder = Widget Function(BuildContext context, MessageNotifier notifier);

typedef ChangeNotifierWidgetBuilder<T> = Widget Function(
    BuildContext context, ChangeNotifier notifier);

typedef StringCallback = Future<String> Function();

typedef EventHandler<T> = void Function(T data);

typedef LoginStepManager = void Function(LoginStep step);

typedef OnTimeout<T> = FutureOr<T> Function();

typedef OnConnectionError = void Function(ServerException exception, Object error);

typedef OnSuccess<T extends Response> = void Function(T response);

typedef RetryBuilder = Widget Function(
    BuildContext context, VoidCallback onRetry, VoidCallback close);
