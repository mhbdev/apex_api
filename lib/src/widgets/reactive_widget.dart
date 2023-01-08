import 'dart:async';

import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';

class ReactiveResponse<DM extends DataModel> {
  final ReactiveState state;
  final BaseResponse<DM>? response;

  ReactiveResponse(this.state, {this.response});
}

class ReactiveError {
  final ServerException exception;
  final Object error;

  ReactiveError(this.exception, this.error);
}

enum ReactiveState { loading, failure, success, error }

class ReactiveController<DM extends DataModel> {
  Future<BaseResponse<DM>> Function()? listener;

  bool get hasClient => listener != null;

  void setListener(Future<BaseResponse<DM>> Function() l) {
    listener = l;
  }

  void removeListener() {
    listener = null;
  }

  Future<BaseResponse<DM>> reload() {
    if (listener != null) {
      return listener!();
    }
    return Future.error(Exception('Could not find any listener!'));
  }
}

class ReactiveWidget<DM extends DataModel> extends StatefulWidget {
  final Request request;
  final Widget loadingWidget;
  final Widget Function(BaseResponse<DM> response, Future<BaseResponse<DM>> Function() onRetry)
      failureWidget;
  final Widget Function(BaseResponse<DM> response, Future<BaseResponse<DM>> Function() onRetry)
      successWidget;
  final Widget Function(
          ServerException exception, Object error, Future<BaseResponse<DM>> Function() onRetry)
      retryWidget;
  final bool ignoreExpireTime;
  final ReactiveController<DM>? controller;
  final void Function(ReactiveState state, Future<BaseResponse<DM>> Function() onRetry,
      {BaseResponse<DM>? response, ReactiveError? error})? listener;
  final Widget Function(ReactiveState state, Widget child)? wrapper;

  const ReactiveWidget({
    Key? key,
    required this.request,
    required this.loadingWidget,
    required this.failureWidget,
    required this.successWidget,
    required this.retryWidget,
    this.listener,
    this.ignoreExpireTime = false,
    this.controller,
    this.wrapper,
  }) : super(key: key);

  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState<DM>();
}

class _ReactiveWidgetState<DM extends DataModel> extends State<ReactiveWidget<DM>>
    with AutomaticKeepAliveClientMixin {
  final StreamController<ReactiveResponse<DM>> _controller =
      StreamController<ReactiveResponse<DM>>();

  @override
  void initState() {
    if (widget.controller != null) {
      widget.controller!.setListener(_sendRequest);
    }
    _sendRequest();
    super.initState();
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller!.removeListener();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReactiveResponse<DM>>(
      stream: _controller.stream,
      builder: (context, snapshot) {
        Widget buildChild() {
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            if (data.state == ReactiveState.loading) {
              return widget.loadingWidget;
            } else if (data.state == ReactiveState.failure) {
              return widget.failureWidget(data.response!, _sendRequest);
            } else if (data.state == ReactiveState.success) {
              return widget.successWidget(data.response!, _sendRequest);
            }
          } else if (snapshot.hasError && snapshot.error != null) {
            final error = snapshot.error! as ReactiveError;
            return widget.retryWidget(error.exception, error.error, _sendRequest);
          }

          return widget.loadingWidget;
        }

        if (widget.wrapper != null && snapshot.hasData && snapshot.data != null) {
          return widget.wrapper!(snapshot.data!.state, buildChild());
        } else {
          return buildChild();
        }
      },
    );
  }

  Future<BaseResponse<DM>> _sendRequest() {
    Completer<BaseResponse<DM>> completer = Completer<BaseResponse<DM>>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.request.send<DM>(
        context,
        onStart: () {
          if (widget.listener != null) {
            widget.listener!(ReactiveState.loading, _sendRequest);
          }
          _controller.add(ReactiveResponse(ReactiveState.loading));
        },
        onSuccess: (response) {
          completer.complete(response);
          if (response.isSuccessful) {
            if (widget.listener != null) {
              widget.listener!(ReactiveState.success, _sendRequest, response: response);
            }
            _controller.add(ReactiveResponse(ReactiveState.success, response: response));
          } else {
            if (widget.listener != null) {
              widget.listener!(ReactiveState.failure, _sendRequest, response: response);
            }
            _controller.add(ReactiveResponse(ReactiveState.failure, response: response));
          }
        },
        showRetry: false,
        showProgress: false,
        ignoreExpireTime: widget.ignoreExpireTime,
        onError: (exception, error) {
          completer.completeError(error);
          final reactiveError = ReactiveError(
            exception,
            error,
          );
          if (widget.listener != null) {
            widget.listener!(ReactiveState.error, _sendRequest, error: reactiveError);
          }
          _controller.addError(
            reactiveError,
          );
        },
      );
    });
    return completer.future;
  }

  @override
  bool get wantKeepAlive => true;
}
