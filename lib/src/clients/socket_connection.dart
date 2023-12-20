import 'dart:convert';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:flutter/material.dart';

import '../../apex_api.dart';
import 'base_connection.dart';

class SocketConnection extends BaseConnection {
  SocketConnection(super.config);

  @override
  Future<BaseResponse<T>> send<T extends DataModel>(
    ApiAction<T> action, {
    VoidCallback? onStart,
    ValueChanged<BaseResponse<T>>? onSuccess,
    String? languageCode,
    bool showLoading = false,
    bool showRetry = false,
    Map<String, String>? headers,
    Encoding? encoding,
    bool ignoreExpireTime = false,
    Duration? requestTimeout,
    CancellationToken? cancellationToken,
    T Function(Json json)? response,
  }) {
    throw UnimplementedError();
  }
}
