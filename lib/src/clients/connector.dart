import 'dart:async';
import 'dart:typed_data';

import 'package:apex_api/src/exceptions/server_exception.dart';
import 'package:apex_api/src/models/request.dart';
import 'package:apex_api/src/notifier/message_notifier.dart';
import 'package:flutter/foundation.dart';

import '../models/connection_config.dart';
import '../models/response.dart';
import '../typedefs.dart';

enum ConnectorTag {
  showProgress,
  hideProgress,
  showRetryDialog,
  hideRetryDialog,
  handleMessage,
}

abstract class Connector extends MessageNotifier {
  bool isInitialized = false;
  final ApiConfig config;
  final Map<Type, ResType> responseModels;

  Connector(this.config, this.responseModels)
      : assert(Uri.parse(config.host).isAbsolute,
            '${config.host} must be a valid url.');

  String get os => kIsWeb
      ? 'W'
      : defaultTargetPlatform == TargetPlatform.android
          ? 'A'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'I'
              : defaultTargetPlatform == TargetPlatform.windows
                  ? 'D'
                  : 'U';

  bool get isConnected;

  void init();

  Future<Res> send<Res extends Response>(Request request,
      {VoidCallback? onStart, bool? showProgress, bool? showRetry});

  void showProgressDialog() => notifyListeners(ConnectorTag.showProgress);

  void hideProgressDialog() => notifyListeners(ConnectorTag.hideProgress);

  void showRetryDialog(ServerException reason) =>
      notifyListeners(ConnectorTag.showRetryDialog, reason);

  void hideRetryDialog() => notifyListeners(ConnectorTag.hideRetryDialog);

  void handleMessage(Response message) => notifyListeners(ConnectorTag.handleMessage, message);

  Future<Res> uploadFile<Res extends Response>(
    Request request, {
    String? fileName,
    String fileKey = 'file',
    String? filePath,
    Uint8List? blobData,
    bool? showProgress,
    bool? showRetry,
    ValueChanged<double>? onProgress,
    ValueChanged<VoidCallback>? cancelToken,
  });
}