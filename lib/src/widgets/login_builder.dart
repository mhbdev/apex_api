import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';

enum LoginType { phone, email }

class LoginBuilder extends StatefulWidget {
  final Widget Function(
      BuildContext context,
      LoginStep step,
      bool isLoading,
      Future<BaseResponse> Function(String username, {String? countryCode}) onDetectUserStatus,
      Future<BaseResponse> Function(String username, String password, {String? countryCode})
          onLogin,
      Future<BaseResponse> Function(String username, {String? countryCode}) onForgotPassword,
      Future<BaseResponse> Function(String username, String password, String otp,
              {String? countryCode})
          onVerify,
      {ValueChanged<LoginStep>? updateStep}) builder;
  final void Function(LoginStep step)? listener;
  final bool showProgress;
  final bool showRetry;
  final LoginType loginType;

  const LoginBuilder({
    Key? key,
    required this.builder,
    this.showProgress = false,
    this.showRetry = false,
    this.listener,
    this.loginType = LoginType.phone,
  }) : super(key: key);

  @override
  State<LoginBuilder> createState() => _LoginBuilderState();
}

class _LoginBuilderState extends State<LoginBuilder> with MountedStateMixin {
  LoginStep _step = LoginStep.showUsername;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _step, _isLoading, (username, {countryCode}) async {
      return (widget.loginType == LoginType.phone && countryCode != null
              ? DetectUserRequest.phone(countryCode, username)
              : DetectUserRequest.email(username, countryCode: countryCode))
          .send<DataModel>(
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
        onComplete: () {
          _isLoading = false;
          mountedSetState();
        },
        showProgress: widget.showProgress,
        showRetry: widget.showRetry,
      );
    }, (username, password, {countryCode}) async {
      return (widget.loginType == LoginType.phone && countryCode != null
              ? LoginRequest.phone(countryCode, username, password)
              : LoginRequest.email(username, password, countryCode: countryCode))
          .send<DataModel>(
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
        onComplete: () {
          _isLoading = false;
          mountedSetState();
        },
        showProgress: widget.showProgress,
        showRetry: widget.showRetry,
      );
    }, (username, {countryCode}) async {
      return (widget.loginType == LoginType.phone && countryCode != null
              ? ForgotPasswordRequest.phone(countryCode, username)
              : ForgotPasswordRequest.email(username, countryCode: countryCode))
          .send<DataModel>(
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
        onComplete: () {
          _isLoading = false;
          mountedSetState();
        },
        showProgress: widget.showProgress,
        showRetry: widget.showRetry,
      );
    }, (username, password, otp, {countryCode}) async {
      return (widget.loginType == LoginType.phone && countryCode != null
              ? VerifyUserRequest.phone(countryCode, username, password, otp)
              : VerifyUserRequest.email(username, password, otp, countryCode: countryCode))
          .send<DataModel>(
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
        onComplete: () {
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
