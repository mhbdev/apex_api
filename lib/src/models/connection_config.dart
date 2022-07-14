import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../cipher/models/key_pair.dart';
import '../exceptions.dart';
import 'request.dart';

class ConnectionConfig {
  const ConnectionConfig(
    this.handlerUrl,
    this.namespace, {
    this.eventName = 'message',
    this.iosKey,
    this.webKey,
    this.androidKey,
    this.privateVersion = 1,
    this.publicVersion = 1,
    required this.uploadHandlerUrl,
    required this.progressWidget,
    required this.options,
    this.port,
    this.debugMode = false,
    this.uploadTimeout = const Duration(seconds: 60),
    this.requestTimeout = const Duration(seconds: 60),
    this.onRetry,
    this.onProgress,
    this.onAuthError,
    this.useSocket = true,
  });

  final KeyPair? iosKey;
  final KeyPair? webKey;
  final KeyPair? androidKey;

  final int? port;
  final OptionBuilder options;

  final String namespace;

  final int privateVersion;
  final int publicVersion;

  final String eventName;

  final bool useSocket;

  final bool debugMode;
  final Duration uploadTimeout;
  final Duration requestTimeout;
  final String handlerUrl;
  final String uploadHandlerUrl;
  final Widget progressWidget;
  final Widget Function(VoidCallback callAction, BuildContext context,
      Request request, RetryReason reason)? onRetry;
  final void Function(BuildContext context, bool show)? onProgress;
  final void Function(BuildContext? context)? onAuthError;
}
