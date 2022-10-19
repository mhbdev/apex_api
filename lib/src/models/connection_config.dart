import 'package:apex_api/apex_api.dart';
import 'package:flutter/foundation.dart';

class ApiConfig extends Equatable {
  const ApiConfig(
    this.host, {
    this.namespace = 'request',
    this.eventName = 'message',
    this.iosKey,
    this.webKey,
    this.androidKey,
    this.windowsKey,
    this.privateVersion = 1,
    this.publicVersion = 1,
    this.uploadHandlerUrl,
    this.options,
    this.port,
    this.debugMode = false,
    this.uploadTimeout = const Duration(seconds: 60),
    this.requestTimeout = const Duration(seconds: 60),
    this.useMocks = false,
    this.useSocket = true,
  }) : assert(!useSocket || port == null,
            'If you are using socket system, you have to pass an integer number as port');

  final KeyPair? iosKey;
  final KeyPair? webKey;
  final KeyPair? androidKey;
  final KeyPair? windowsKey;

  final String host;
  final int? port;
  final OptionBuilder? options;

  final String namespace;

  final int privateVersion;
  final int publicVersion;

  final String eventName;

  final bool useSocket;
  final bool useMocks;

  final bool debugMode;
  final Duration uploadTimeout;
  final Duration requestTimeout;
  final String? uploadHandlerUrl;

  String? get secretKey => encrypt
      ? (kIsWeb
          ? webKey!.secretKey
          : (defaultTargetPlatform == TargetPlatform.android
              ? androidKey!.secretKey
              : (defaultTargetPlatform == TargetPlatform.windows
                  ? windowsKey!.secretKey
                  : iosKey!.secretKey)))
      : null;

  String? get publicKey => encrypt
      ? (kIsWeb
          ? webKey!.publicKey
          : (defaultTargetPlatform == TargetPlatform.android
              ? androidKey!.publicKey
              : (defaultTargetPlatform == TargetPlatform.windows
                  ? windowsKey!.publicKey
                  : iosKey!.publicKey)))
      : null;

  bool get encrypt => kIsWeb
      ? webKey != null
      : (defaultTargetPlatform == TargetPlatform.android
          ? androidKey != null
          : (defaultTargetPlatform == TargetPlatform.windows
              ? windowsKey != null
              : iosKey != null));

  ApiConfig copyWith(
      {String? host,
      String? namespace,
      String? eventName,
      KeyPair? iosKey,
      KeyPair? webKey,
      KeyPair? windowsKey,
      KeyPair? androidKey,
      int? privateVersion,
      int? publicVersion,
      String? uploadHandlerUrl,
      OptionBuilder? options,
      int? port,
      bool? debugMode,
      Duration? uploadTimeout,
      Duration? requestTimeout,
      bool? useSocket,
      bool? useMocks}) {
    return ApiConfig(
      host ?? this.host,
      useMocks: useMocks ?? this.useMocks,
      useSocket: useSocket ?? this.useSocket,
      debugMode: debugMode ?? this.debugMode,
      webKey: webKey ?? this.webKey,
      androidKey: androidKey ?? this.androidKey,
      iosKey: iosKey ?? this.iosKey,
      windowsKey: windowsKey ?? this.windowsKey,
      eventName: eventName ?? this.eventName,
      namespace: namespace ?? this.namespace,
      options: options ?? this.options,
      port: port ?? this.port,
      privateVersion: privateVersion ?? this.privateVersion,
      publicVersion: publicVersion ?? this.publicVersion,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      uploadTimeout: uploadTimeout ?? this.uploadTimeout,
      uploadHandlerUrl: uploadHandlerUrl ?? this.uploadHandlerUrl,
    );
  }

  @override
  List<Object?> get props => [
        host,
        port,
        namespace,
        eventName,
        privateVersion,
        publicVersion,
        useSocket,
        uploadHandlerUrl
      ];
}
