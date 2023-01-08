import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';

class LoginBuilder extends StatefulWidget {
  final Widget Function(
      BuildContext context,
      LoginStep step,
      bool isLoading,
      Future<BaseResponse> Function(String countryCode, String username) onDetectUserStatus,
      Future<BaseResponse> Function(String countryCode, String username, String password) onLogin,
      Future<BaseResponse> Function(String countryCode, String username) onForgotPassword,
      Future<BaseResponse> Function(
              String countryCode, String username, String password, String otp)
          onVerify,
      {ValueChanged<LoginStep>? updateStep}) builder;
  final void Function(LoginStep step)? listener;
  final bool showProgress;
  final bool showRetry;

  const LoginBuilder({
    Key? key,
    required this.builder,
    this.showProgress = false,
    this.showRetry = false,
    this.listener,
  }) : super(key: key);

  @override
  State<LoginBuilder> createState() => _LoginBuilderState();
}

class _LoginBuilderState extends State<LoginBuilder> with WidgetLoadMixin, MountedStateMixin {
  LoginStep _step = LoginStep.showUsername;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _step, _isLoading, (countryCode, username) async {
      return DetectUserRequest(countryCode, username).send(
        context,
        onStart: () {
          _isLoading = true;
          mountedSetState();
        },
        onSuccess: (response) {
          _step = _escapeLoginStep(response.loginStep);
          _isLoading = false;
          mountedSetState();
          _notifyListener();
        },
        onError: (exception, error) {
          _isLoading = false;
          mountedSetState();
        },
        showProgress: widget.showProgress,
        showRetry: widget.showRetry,
      );
    }, (countryCode, username, password) async {
      return LoginRequest(countryCode, username, password).send(
        context,
        onStart: () {
          _isLoading = true;
          mountedSetState();
        },
        onSuccess: (response) {
          _step = _escapeLoginStep(response.loginStep);
          _isLoading = false;
          mountedSetState();
          _notifyListener();
        },
        onError: (exception, error) {
          _isLoading = false;
          mountedSetState();
        },
        showProgress: widget.showProgress,
        showRetry: widget.showRetry,
      );
    }, (countryCode, username) async {
      return ForgotPasswordRequest(countryCode, username).send(
        context,
        onStart: () {
          _isLoading = true;
          mountedSetState();
        },
        onSuccess: (response) {
          _step = _escapeLoginStep(response.loginStep);
          _isLoading = false;
          mountedSetState();
          _notifyListener();
        },
        onError: (exception, error) {
          _isLoading = false;
          mountedSetState();
        },
        showProgress: widget.showProgress,
        showRetry: widget.showRetry,
      );
    }, (countryCode, username, password, otp) async {
      return VerifyUserRequest(countryCode, username, password, otp).send(
        context,
        onStart: () {
          _isLoading = true;
          mountedSetState();
        },
        onSuccess: (response) {
          _step = _escapeLoginStep(response.loginStep);
          _isLoading = false;
          mountedSetState();
          _notifyListener();
        },
        onError: (exception, error) {
          _isLoading = false;
          mountedSetState();
        },
        showProgress: widget.showProgress,
        showRetry: widget.showRetry,
      );
    }, updateStep: (step) {
      mountedSetState(() {
        _step = _escapeLoginStep(step);
      });
    });
  }

  @override
  void onLoad(BuildContext context) {}

  LoginStep _escapeLoginStep(LoginStep step) {
    if (step != LoginStep.success && step != LoginStep.failure && step != LoginStep.showUpgrade) {
      return step;
    }
    return _step;
  }

  void _notifyListener() {
    if (widget.listener != null) {
      widget.listener!(_step);
    }
  }
}
