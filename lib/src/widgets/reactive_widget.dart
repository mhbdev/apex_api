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
  Future<BaseResponse<DM>> Function([bool? silent])? listener;

  bool get hasClient => listener != null;

  void setListener(Future<BaseResponse<DM>> Function([bool? silent]) l) {
    listener = l;
  }

  void removeListener() {
    listener = null;
  }

  Future<BaseResponse<DM>> reload([bool? silent]) {
    if (listener != null) {
      return listener!(silent);
    }
    return Future.error(Exception('Could not find any listener!'));
  }
}

class ReactiveWidget<DM extends DataModel> extends StatefulWidget {
  final Request request;
  final Widget? loadingWidget;
  final Widget Function(
          BaseResponse<DM> response, Future<BaseResponse<DM>> Function([bool? silent]) onRetry)
      successWidget;
  final Widget Function(
          BaseResponse<DM> response, Future<BaseResponse<DM>> Function([bool? silent]) onRetry)?
      failureWidget;
  final Widget Function(ServerException exception, Object error,
      Future<BaseResponse<DM>> Function([bool? silent]) onRetry)? retryWidget;
  final bool ignoreExpireTime;
  final ReactiveController<DM>? controller;
  final void Function(
      ReactiveState state, Future<BaseResponse<DM>> Function([bool? silent]) onRetry,
      {BaseResponse<DM>? response, ReactiveError? error})? listener;
  final Widget Function(
      ReactiveState state, Widget child, Future<BaseResponse<DM>> Function([bool? silent]) onRetry,
      {BaseResponse<DM>? response})? wrapper;
  final DM Function(Json json)? response;

  /// Set this parameter to `true` if you need to save different responses of the same request (action)
  /// Can be used for actions with pagination feature
  final bool storeResponses;
  final StreamController<ReactiveResponse<DM>>? streamController;

  const ReactiveWidget({
    Key? key,
    required this.request,
    this.loadingWidget,
    required this.successWidget,
    this.failureWidget,
    this.retryWidget,
    this.response,
    this.listener,
    this.ignoreExpireTime = false,
    this.controller,
    this.wrapper,
    this.storeResponses = false,
    this.streamController,
  }) : super(key: key);

  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState<DM>();
}

class _ReactiveWidgetState<DM extends DataModel> extends State<ReactiveWidget<DM>>
    with AutomaticKeepAliveClientMixin, WidgetLoadMixin, MountedStateMixin {
  late final StreamController<ReactiveResponse<DM>> _controller;

  Map<Request, BaseResponse<DM>> _storedRequests = {};

  @override
  void initState() {
    _controller = widget.streamController ?? StreamController<ReactiveResponse<DM>>();
    _sendRequest();
    super.initState();
  }

  @override
  void dispose() {
    _storedRequests.clear();
    if (widget.controller != null) {
      widget.controller!.removeListener();
      if (widget.streamController == null) {
        if (!_controller.isClosed) _controller.close();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<ReactiveResponse<DM>>(
      stream: _controller.stream,
      builder: (context, snapshot) {
        Widget buildChild() {
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            if (data.state == ReactiveState.loading) {
              return widget.loadingWidget ??
                  context.http.config.reactiveWidgetOptions?.loadingWidget ??
                  const Center(
                    child: CircularProgressIndicator(),
                  );
            } else if (data.state == ReactiveState.failure) {
              return Function.apply(
                  widget.failureWidget ?? context.http.config.reactiveWidgetOptions!.failureWidget,
                  [data.response!, _sendRequest]);
            } else if (data.state == ReactiveState.success) {
              return widget.successWidget(data.response!, _sendRequest);
            }
          } else if (snapshot.hasError && snapshot.error != null) {
            final error = snapshot.error! as ReactiveError;
            return Function.apply(
                widget.retryWidget ?? context.http.config.reactiveWidgetOptions!.retryWidget,
                [error.exception, error.error, _sendRequest]);
          }

          return widget.loadingWidget ??
              context.http.config.reactiveWidgetOptions?.loadingWidget ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        if (widget.wrapper != null) {
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            if (data.state == ReactiveState.success || data.state == ReactiveState.failure) {
              return widget.wrapper!(snapshot.data!.state, buildChild(), _sendRequest,
                  response: data.response);
            }
            return widget.wrapper!(snapshot.data!.state, buildChild(), _sendRequest);
          } else {
            return widget.wrapper!(ReactiveState.error, buildChild(), _sendRequest);
          }
        } else {
          return buildChild();
        }
      },
    );
  }

  Future<BaseResponse<DM>> _sendRequest([bool? silent]) {
    /// It was necessary because some frames and states were being passed
    mountedSetState();
    Completer<BaseResponse<DM>> completer = Completer<BaseResponse<DM>>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.http.post<DM>(
        widget.request,
        response: widget.response,
        onStart: () {
          if (widget.listener != null) {
            widget.listener!(ReactiveState.loading, _sendRequest);
          }
          if (silent != true) {
            if (!_controller.isClosed) {
              _controller.add(ReactiveResponse(ReactiveState.loading));
            }
          }
        },
        showRetry: false,
        showProgress: false,
        ignoreExpireTime: widget.ignoreExpireTime,
      ).then((response) {
        if (widget.storeResponses) {
          if (_storedRequests[widget.request] != null) {
            response = _storedRequests[widget.request]!;
          }
          _storedRequests[widget.request] = response;
        }

        if (response.hasError) {
          completer.completeError(response.error!);
          final reactiveError = ReactiveError(
            response.error!,
            response.errorMessage ?? response.error.toString(),
          );
          if (widget.listener != null) {
            widget.listener!(ReactiveState.error, _sendRequest, error: reactiveError);
          }
          if (silent != true) {
            if (!_controller.isClosed) {
              _controller.addError(reactiveError);
            }
          }
          return;
        }

        completer.complete(response);

        if (response.isSuccessful) {
          if (widget.listener != null) {
            widget.listener!(ReactiveState.success, _sendRequest, response: response);
          }
          // if (silent != true) {
          if (!_controller.isClosed) {
            _controller.add(ReactiveResponse(ReactiveState.success, response: response));
          }
          // }
        } else {
          if (widget.listener != null) {
            widget.listener!(ReactiveState.failure, _sendRequest, response: response);
          }
          if (silent != true) {
            if (!_controller.isClosed) {
              _controller.add(ReactiveResponse(ReactiveState.failure, response: response));
            }
          }
        }
      });
    });
    return completer.future;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void onLoad(BuildContext context) {
    if (widget.controller != null) {
      widget.controller!.setListener(_sendRequest);
    }
  }
}
