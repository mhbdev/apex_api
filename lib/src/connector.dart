import 'package:apex_api/src/exceptions.dart';
import 'package:apex_api/src/models/request.dart';
import 'package:apex_api/src/notifier/message_notifier.dart';
import 'package:flutter/foundation.dart';

import 'cipher/crypto.dart';
import 'models/connection_config.dart';
import 'models/response.dart';
import 'typedefs.dart';

abstract class Connector extends MessageNotifier {
  bool isInitialized = false;
  final ConnectionConfig config;
  final Map<Type, ResType> responseModels;
  final int maxRetry = 2;
  int retried = 1;

  Connector(this.config, this.responseModels)
      : assert(Uri.parse(config.handlerUrl).isAbsolute,
            '${config.handlerUrl} must be a valid url.');

  String get _secretKey => kIsWeb
      ? config.webKey!.secretKey
      : (defaultTargetPlatform == TargetPlatform.android
          ? config.androidKey!.secretKey
          : config.iosKey!.secretKey);

  String get _publicKey => kIsWeb
      ? config.webKey!.publicKey
      : (defaultTargetPlatform == TargetPlatform.android
          ? config.androidKey!.publicKey
          : config.iosKey!.publicKey);

  bool get encrypt => kIsWeb
      ? config.webKey != null
      : (defaultTargetPlatform == TargetPlatform.android
          ? config.androidKey != null
          : config.iosKey != null);

  String get os => kIsWeb
      ? 'W'
      : defaultTargetPlatform == TargetPlatform.android
          ? 'A'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'I'
              : 'U';

  Crypto get crypto => Crypto(_secretKey, _publicKey);

  bool get isConnected;

  void init();

  Future<Res> send<Res extends ResponseModel>(Request request,
      {VoidCallback? onStart, bool? showProgress});

  void showProgressDialog() {}

  void hideProgressDialog() {}

  void showRetryDialog(RetryReason responseIsNull) {}
}
