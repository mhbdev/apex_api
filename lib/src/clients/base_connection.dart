import 'dart:convert';

import 'package:apex_api/src/clients/http_connection.dart';
import 'package:apex_api/src/clients/socket_connection.dart';
import 'package:cancellation_token/cancellation_token.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import '../../apex_api.dart';
import '../../cipher/crypto.dart';
import 'package:http/http.dart' as http;

abstract class BaseConnection extends ChangeNotifier {
  final ApiConfig config;
  final OnRetry? onRetry;
  final OnMessage? onMessage;
  final OnLoginStepChanged? onLoginStepChanged;
  final Map<Type, ResType>? responseModels;
  final Logger logger;

  factory BaseConnection.socket(ApiConfig config) => SocketConnection(config);

  factory BaseConnection.http(
    ApiConfig config, {
    http.Client? client,
    OnLoginStepChanged? onLoginStepChanged,
    OnMessage? onMessage,
    OnRetry? onRetry,
    Map<Type, ResType>? responseModels,
  }) =>
      HttpConnection(
        config,
        client: client,
        onLoginStepChanged: onLoginStepChanged,
        onMessage: onMessage,
        onRetry: onRetry,
        responseModels: responseModels,
      );

  // State
  bool _isShowingProgress = false;

  bool get isShowingProgress => _isShowingProgress;

  BaseConnection(
    this.config, {
    this.onRetry,
    this.onMessage,
    this.onLoginStepChanged,
    Map<Type, ResType>? responseModels,
  })  : assert(Uri.parse(config.host).isAbsolute, '${config.host} must be a valid url.'),
        assert(config.port == null || (config.port! >= -1 && config.port! <= 65535),
            '${config.port} must be a number between -1 and 65535. or null.'),
        responseModels = {
          FetchCountries: FetchCountries.fromJson,
          FetchProvinces: FetchProvinces.fromJson,
          UploadResponse: UploadResponse.fromJson,
          DataModel: DataModel.fromJson,
          if (responseModels != null) ...responseModels,
        },
        logger = config.logger;

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
  });

  Future<String> encrypt(Crypto crypto, Request request) async {
    String formattedRequest = jsonEncode(await request.toJson());

    if (request.isPublic) {
      return base64Encode(utf8.encode(formattedRequest));
    }

    if (request.encrypt == false) {
      return formattedRequest;
    }

    return crypto.encrypt(formattedRequest);
  }

  String decrypt(Crypto crypto, Request request, String responseMessage) {
    if (request.encrypt == false || request.isPublic) {
      return responseMessage;
    }

    return crypto.decrypt(responseMessage);
  }

  void showProgress() {
    if (_isShowingProgress == false) {
      _isShowingProgress = true;
      notifyListeners();
    }
  }

  void hideProgress() {
    if (_isShowingProgress == true) {
      _isShowingProgress = false;
      notifyListeners();
    }
  }
}
