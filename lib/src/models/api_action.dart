import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';

class ApiAction<T extends DataModel> {
  final Request request;
  final T Function(Json json)? response;

  ApiAction(this.request, {this.response});
}

extension ApiActionExtension<T extends DataModel> on ApiAction<T> {
  Future<BaseResponse<T>> send(BuildContext context, {
    T Function(Json json)? response,
    String? languageCode,
    bool showProgress = false,
    bool showRetry = false,
    VoidCallback? onStart,
    VoidCallback? onComplete,
    ValueChanged<BaseResponse<T>>? onSuccess,
    OnConnectionError? onError,
    bool ignoreExpireTime = false,
    Duration? requestTimeout,
  }) {
    try {
      return context.http
          .post<T>(ApiAction<T>(request, response: this.response ?? response),
          showProgress: showProgress,
          languageCode: languageCode,
          showRetry: showRetry,
          onStart: onStart,
          onSuccess: onSuccess,
          ignoreExpireTime: ignoreExpireTime,
          requestTimeout: requestTimeout)
          .catchError((e) {
        if (onError != null) {
          onError(ServerErrorException('Maybe timeout!'), e);
        }
        return Future.value(BaseResponse<T>(error: ServerErrorException()));
      }).whenComplete(() {
        if (onComplete != null) {
          onComplete();
        }
      });
    } catch (e) {
      if (onError != null) {
        onError(ServerErrorException('Maybe timeout!'), e);
      }
      rethrow;
    }
  }
}