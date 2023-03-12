import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../../cipher/models/key_pair.dart';

class ApiConfig extends Equatable {
  const ApiConfig(
    this.host, {
    this.handlerNamespace = '/',
    this.namespace = 'data',
    this.eventName = 'message',
    this.languageCode = 'EN',
    this.iosKey,
    this.webKey,
    this.androidKey,
    this.windowsKey,
    this.privateVersion = 1,
    this.publicVersion = 1,
    this.dbVersion = '1',
    this.options,
    this.port,
    this.logLevel = Level.debug,
    this.uploadTimeout = const Duration(minutes: 5),
    this.requestTimeout = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 10),
    this.useMocks = false,
    this.onTimeout,
  });

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

  final String languageCode;
  final String eventName;

  final bool useMocks;

  final Level logLevel;
  final Duration uploadTimeout;
  final Duration requestTimeout;
  final Duration connectionTimeout;

  final FutureOr<T> Function<T>()? onTimeout;

  final String dbVersion;

  final String handlerNamespace;

  bool get debugMode => logLevel != Level.nothing;

  String? get secretKey => encrypt
      ? (kIsWeb || debugMode
          ? webKey!.secretKey
          : (defaultTargetPlatform == TargetPlatform.android
              ? androidKey!.secretKey
              : (defaultTargetPlatform == TargetPlatform.windows
                  ? windowsKey!.secretKey
                  : iosKey!.secretKey)))
      : null;

  String? get publicKey => encrypt
      ? (kIsWeb || debugMode
          ? webKey!.publicKey
          : (defaultTargetPlatform == TargetPlatform.android
              ? androidKey!.publicKey
              : (defaultTargetPlatform == TargetPlatform.windows
                  ? windowsKey!.publicKey
                  : iosKey!.publicKey)))
      : null;

  bool get encrypt => kIsWeb || debugMode
      ? webKey != null
      : (defaultTargetPlatform == TargetPlatform.android
          ? androidKey != null
          : (defaultTargetPlatform == TargetPlatform.windows
              ? windowsKey != null
              : iosKey != null));

  String get os => kIsWeb || debugMode
      ? 'W'
      : defaultTargetPlatform == TargetPlatform.android
          ? 'A'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'I'
              : defaultTargetPlatform == TargetPlatform.windows
                  ? 'D'
                  : 'U';

  ApiConfig copyWith(
      {String? host,
      String? namespace,
      String? eventName,
      String? languageCode,
      KeyPair? iosKey,
      KeyPair? webKey,
      KeyPair? windowsKey,
      KeyPair? androidKey,
      int? privateVersion,
      int? publicVersion,
      String? uploadHandlerUrl,
      OptionBuilder? options,
      int? port,
      Level? logLevel,
      Duration? uploadTimeout,
      Duration? requestTimeout,
      bool? useMocks,
      Duration? connectionTimeout,
      String? dbVersion,
      FutureOr<T> Function<T>()? onTimeout,
      String? handlerNamespace}) {
    return ApiConfig(
      host ?? this.host,
      useMocks: useMocks ?? this.useMocks,
      logLevel: logLevel ?? this.logLevel,
      webKey: webKey ?? this.webKey,
      androidKey: androidKey ?? this.androidKey,
      iosKey: iosKey ?? this.iosKey,
      windowsKey: windowsKey ?? this.windowsKey,
      languageCode: languageCode ?? this.languageCode,
      eventName: eventName ?? this.eventName,
      namespace: namespace ?? this.namespace,
      options: options ?? this.options,
      port: port ?? this.port,
      privateVersion: privateVersion ?? this.privateVersion,
      publicVersion: publicVersion ?? this.publicVersion,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      uploadTimeout: uploadTimeout ?? this.uploadTimeout,
      dbVersion: dbVersion ?? this.dbVersion,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      onTimeout: onTimeout ?? this.onTimeout,
      handlerNamespace: handlerNamespace ?? this.handlerNamespace,
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
      ];
}
