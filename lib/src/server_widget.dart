import 'dart:async';
import 'dart:typed_data';

import 'package:apex_api/src/server.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'clients/clients.dart';
import 'clients/connector.dart';
import 'models/request.dart';
import 'models/response.dart';
import 'notifier/message_notifier_builder.dart';
import 'socket_join_controller.dart';
import 'socket_stream.dart';
import 'typedefs.dart';
import 'utils/mixins.dart';
import 'widgets/connection_badge.dart';

class ServerWidget extends InheritedWidget {
  final Api server;
  final ServerWrapperState data;

  const ServerWidget({
    super.key,
    required super.child,
    required this.server,
    required this.data,
  });

  static ServerWrapperState of(BuildContext context, {bool build = true}) {
    return build
        ? context.dependOnInheritedWidgetOfExactType<ServerWidget>()!.data
        : context.findAncestorWidgetOfExactType<ServerWidget>()!.data;
  }

  @override
  bool updateShouldNotify(ServerWidget oldWidget) {
    return oldWidget.server != server;
  }
}

class ServerWrapper extends StatefulWidget {
  final Locale locale;
  final Api api;
  final Widget child;
  final WidgetBuilder? progressBuilder;
  final RetryBuilder? retryBuilder;
  final LoginStepManager loginStepManager;
  final bool showConnectionBadge;
  final ValueChanged<Response>? handleMessage;

  /// You can obtain this globalKey like this:
  /// add this snippet at the top of your MaterialApp builder method
  /// the `child` parameter in builder inputs is always a `Navigator` widget
  /// ```
  /// final navigatorKey = child!.key as GlobalKey<NavigatorState>;
  /// ```
  /// And then pass this key to `ServerWrapper` widget and return an instance of this class to your builder.
  final GlobalKey<NavigatorState> navKey;

  const ServerWrapper({
    super.key,
    this.locale = const Locale('fa', 'IR'),
    this.progressBuilder,
    this.retryBuilder,
    required this.navKey,
    required this.child,
    required this.api,
    required this.loginStepManager,
    this.handleMessage,
    this.showConnectionBadge = true,
  });

  @override
  State<ServerWrapper> createState() => ServerWrapperState();
}

class ServerWrapperState extends State<ServerWrapper> with WidgetLoadMixin, MountedStateMixin {
  bool isShowingProgress = false;
  bool isShowingRetry = false;
  Request? _request;
  bool? _showProgress, _showRetry, _ignoreExpireTime;
  dynamic _onSuccess, _onError, _onStart;

  @override
  void didUpdateWidget(covariant ServerWrapper oldWidget) {
    if (widget.api != oldWidget.api || widget.navKey != oldWidget.navKey) {
      mountedSetState();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ServerWidget(
      data: this,
      server: widget.api,
      child: Stack(
        children: [
          widget.child,
          if (widget.showConnectionBadge && connector is ApexSocket)
            PositionedDirectional(
              start: 16,
              bottom: 16,
              child: MessageNotifierBuilder(
                notifier: connector,
                builder: (context, value) {
                  return ConnectionBadge(server: widget.api, locale: widget.locale);
                },
              ),
            ),
        ],
      ),
    );
  }

  Connector get connector => widget.api.connector;

  Future<Res> request<Res extends Response>(
    Request request, {
    bool? showProgress,
    bool? showRetry,
    VoidCallback? onStart,
    OnSuccess<Res>? onSuccess,
    OnConnectionError? onError,
    bool ignoreExpireTime = false,
  }) {
    _request = request;
    _showProgress = showProgress;
    _showRetry = showRetry;
    _onStart = onStart;
    _onSuccess = onSuccess;
    _onError = onError;
    _ignoreExpireTime = ignoreExpireTime;

    return widget.api.request<Res>(
      request,
      languageCode: widget.locale.languageCode,
      showProgress: showProgress,
      showRetry: showRetry,
      onStart: onStart,
      onSuccess: onSuccess,
      onError: onError,
      ignoreExpireTime: ignoreExpireTime,
      manageLoginStep: widget.loginStepManager,
    );
  }

  Future<bool> join<Res extends Response>(
    JoinGroupRequest joinRequest, {
    VoidCallback? onStart,
    StreamSocket<Res>? stream,
    SocketJoinController<Res>? controller,
    void Function(Res res)? onListen,
    bool? showProgress,
    bool? showRetry,
  }) {
    return widget.api.join<Res>(joinRequest,
        showProgress: showProgress,
        showRetry: showRetry,
        onStart: onStart,
        onListen: onListen,
        controller: controller,
        stream: stream,
        loginStepManager: widget.loginStepManager);
  }

  Future<Res> subscribePublic<Res extends Response>(String event,
      [OnSuccess<Res>? onSuccess]) async {
    final futureResponse = widget.api.subscribePublic<Res>(event);
    if (onSuccess != null) {
      onSuccess(await futureResponse);
    }
    return futureResponse;
  }

  void unsubscribePublic(String event) {
    widget.api.unsubscribePublic(event);
  }

  Future<Res> uploadFile<Res extends Response>(
    Request request, {
    String? fileName,
    String fileKey = 'file',
    String? filePath,
    Uint8List? blobData,
    bool? showProgress,
    // bool? showRetry,
    OnSuccess<Res>? onSuccess,
    OnConnectionError? onError,
    ValueChanged<double>? onProgress,
    ValueChanged<VoidCallback>? cancelToken,
    VoidCallback? onStart,
  }) {
    // TODO : implementation of retry request for uploads
    // _request = request;
    // _showProgress = showProgress;
    // _showRetry = showRetry;
    // _onStart = onStart;
    // _onSuccess = onSuccess;
    // _onError = onError;

    return widget.api.uploadFile<Res>(
      request,
      languageCode: widget.locale.languageCode,
      showProgress: showProgress,
      // showRetry: showRetry,
      onProgress: onProgress,
      cancelToken: cancelToken,
      blobData: blobData,
      filePath: filePath,
      fileKey: fileKey,
      fileName: fileName,
      onStart: onStart,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  @override
  void onLoad(context) {
    connector.init();
    connector.addListener((tag, [message]) {
      if (tag is ConnectorTag) {
        switch (tag) {
          case ConnectorTag.handleMessage:
            if (widget.handleMessage != null) {
              widget.handleMessage!(message);
            }
            break;
          case ConnectorTag.showProgress:
            if (!isShowingProgress) {
              isShowingProgress = true;
              _showDialog((context) => widget.progressBuilder != null
                  ? widget.progressBuilder!(context)
                  : Builder(
                      builder: (context) {
                        final progressWidget = Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(32),
                          child: const CircularProgressIndicator(),
                        );
                        final child = WillPopScope(
                          onWillPop: () => Future(() => false),
                          child: Align(
                            alignment: Alignment.center,
                            child: progressWidget,
                          ),
                        );

                        return Material(
                          type: MaterialType.transparency,
                          child: child,
                        );
                      },
                    ));
            }
            break;
          case ConnectorTag.hideProgress:
            if (isShowingProgress) {
              _pop();
              isShowingProgress = false;
            }
            break;
          case ConnectorTag.showRetryDialog:
            if (!isShowingRetry) {
              isShowingRetry = true;
              _showDialog(
                dismissible: true,
                (context) => widget.retryBuilder != null
                    ? widget.retryBuilder!(
                        context,
                        _onRetry,
                        _onCloseRetry,
                      )
                    : CupertinoAlertDialog(
                        content: Text(
                          widget.locale.languageCode.toUpperCase() == 'FA'
                              ? 'مشکلی در ارسال درخواست شما پیش آمده. آیا میخواهید درخواست قبلی مجدد تکرار شود؟'
                              : 'Something went wrong during sending your request. Do you want to resend current request?',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: _onRetry,
                            child: Text(
                              widget.locale.languageCode.toUpperCase() == 'FA' ? 'بله' : 'Yes',
                            ),
                          ),
                          CupertinoDialogAction(
                            onPressed: _onCloseRetry,
                            child: Text(
                              widget.locale.languageCode.toUpperCase() == 'FA' ? 'خیر' : 'No',
                            ),
                          ),
                        ],
                      ),
              );
            }
            break;
          case ConnectorTag.hideRetryDialog:
            if (isShowingRetry) {
              isShowingRetry = false;
              _pop();
            }
            break;
        }
      }
    });
  }

  void _pop({Object? result, bool? rootNavigator}) {
    return rootNavigator != null
        ? Navigator.of(widget.navKey.currentContext!, rootNavigator: rootNavigator).pop(result)
        : widget.navKey.currentState!.pop(result);
  }

  Future<T?> _showDialog<T>(WidgetBuilder builder,
      {bool useRootNavigator = true, bool dismissible = false}) {
    return showDialog<T>(
        useRootNavigator: true,
        barrierDismissible: dismissible,
        context: widget.navKey.currentContext!,
        builder: builder);
  }

  void _onRetry<Res extends Response>() {
    if (_request != null) {
      _pop();
      isShowingRetry = false;
      request<Res>(
        _request!,
        showRetry: _showRetry,
        showProgress: _showProgress,
        ignoreExpireTime: _ignoreExpireTime ?? false,
        onError: _onError,
        onSuccess: _onSuccess,
        onStart: _onStart,
      );
    }
  }

  void _onCloseRetry() {
    _pop();
    isShowingRetry = false;
  }
}
