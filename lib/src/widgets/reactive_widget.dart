import 'dart:async';

import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';

class ReactiveResponse<Res extends Response> {
  final ReactiveState state;
  final Res? response;

  ReactiveResponse(this.state, {this.response});
}

class ReactiveError {
  final ServerException exception;
  final Object error;

  ReactiveError(this.exception, this.error);
}

enum ReactiveState { loading, failure, success, error }

class ReactiveController extends ChangeNotifier {
  void reload() {
    notifyListeners();
  }
}

class ReactiveWidget<Res extends Response> extends StatefulWidget {
  final Request request;
  final Widget loadingWidget;
  final Widget Function(Res response, VoidCallback onRetry) failureWidget;
  final Widget Function(Res response, VoidCallback onRetry) successWidget;
  final Widget Function(ServerException exception, Object error, VoidCallback onRetry) retryWidget;
  final bool ignoreExpireTime;
  final ReactiveController? controller;
  final void Function(ReactiveState state, VoidCallback onRetry,
      {Res? response, ReactiveError? error})? listener;

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
  }) : super(key: key);

  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState<Res>();
}

class _ReactiveWidgetState<Res extends Response> extends State<ReactiveWidget<Res>>
    with WidgetLoadMixin {
  final StreamController<ReactiveResponse<Res>> _controller =
      StreamController<ReactiveResponse<Res>>();

  @override
  void initState() {
    if (widget.controller != null) {
      widget.controller!.addListener(_sendRequest);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller!.removeListener(_sendRequest);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReactiveResponse<Res>>(
      stream: _controller.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          print('hasData');
          final data = snapshot.data!;
          if (data.state == ReactiveState.loading) {
            print('loading');
            return widget.loadingWidget;
          } else if (data.state == ReactiveState.failure) {
            print('failure');
            return widget.failureWidget(data.response!, _sendRequest);
          } else if (data.state == ReactiveState.success) {
            print('success');
            return widget.successWidget(data.response!, _sendRequest);
          }
        } else if (snapshot.hasError && snapshot.error != null) {
          print('hasError');
          final error = snapshot.error! as ReactiveError;
          return widget.retryWidget(error.exception, error.error, _sendRequest);
        }

        print('unknown');
        return widget.loadingWidget;
      },
    );
  }

  @override
  void onLoad(BuildContext context) {
    _sendRequest();
  }

  void _sendRequest() {
    widget.request.send<Res>(
      context,
      onStart: () {
        print('sending request...');
        if (widget.listener != null) {
          widget.listener!(ReactiveState.loading, _sendRequest);
        }
        _controller.add(ReactiveResponse(ReactiveState.loading));
      },
      onSuccess: (response) {
        print('response returned');
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
        print('error occured');
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
  }
}
