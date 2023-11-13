import 'package:flutter/material.dart';

import '../../apex_api.dart';

class ReactiveWidgetOptions {
  final Widget Function(
      BaseResponse response, Future<BaseResponse> Function([bool? silent]) onRetry) failureWidget;
  final Widget Function(ServerException exception, Object error,
      Future<BaseResponse> Function([bool? silent]) onRetry) retryWidget;
  final Widget loadingWidget;
  final int retryAttempts;

  ReactiveWidgetOptions({
    required this.failureWidget,
    required this.retryWidget,
    required this.loadingWidget,
    this.retryAttempts = 0,
  });
}
