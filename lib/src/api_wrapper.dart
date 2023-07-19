import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ApiWrapper extends StatelessWidget {
  final ApiConfig config;
  final Widget child;
  final GlobalKey<NavigatorState> navKey;
  final void Function(Request request, BaseResponse response)? messageHandler;
  final ValueChanged<LoginStep>? loginStepHandler;
  final Map<Type, ResType>? responseModels;
  final Widget? progressWidget;
  final Widget Function(BuildContext context, VoidCallback onRetry)? retryBuilder;
  final bool useSocket;

  /// If you want to check the host availability in background set this to true otherwise
  /// [progressWidget] will be used as a placeholder until the best host be selected!
  final bool checkHostsInBackground;

  const ApiWrapper({
    Key? key,
    required this.config,
    required this.child,
    required this.navKey,
    this.messageHandler,
    this.loginStepHandler,
    this.responseModels,
    this.progressWidget,
    this.retryBuilder,
    this.useSocket = false,
    this.checkHostsInBackground = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => HttpAlt(
            config,
            useSocket: useSocket,
            navKey: navKey,
            progressWidget: progressWidget,
            messageHandler: messageHandler,
            loginStepHandler: loginStepHandler,
            responseModels: responseModels,
            retryBuilder: retryBuilder,
          ),
        ),
      ],
      child: config.hostCheck
          ? _ApiWrapperBuilder(
              config: config,
              checkHostsInBackground: checkHostsInBackground,
              progressWidget: progressWidget,
              child: child,
            )
          : child,
    );
  }
}

/// Created this widget to make sure we have access to HttpAlt Provider using its context
class _ApiWrapperBuilder extends StatefulWidget {
  final Widget child;

  /// A simple CircularProgressIndicator will be used if null
  final Widget? progressWidget;

  /// If you want to check the host availability in background set this to true otherwise
  /// [progressWidget] will be used as a placeholder until the best host be selected!
  final bool checkHostsInBackground;

  final ApiConfig config;

  const _ApiWrapperBuilder({
    super.key,
    required this.child,
    this.checkHostsInBackground = true,
    this.progressWidget,
    required this.config,
  });

  @override
  State<_ApiWrapperBuilder> createState() => _ApiWrapperBuilderState();
}

class _ApiWrapperBuilderState extends State<_ApiWrapperBuilder> with WidgetLoadMixin {
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);

  @override
  void initState() {
    if (widget.config.hostCheck) {
      if (widget.checkHostsInBackground) {
        _loading.value = false;
      } else {
        _loading.value = true;
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !widget.checkHostsInBackground
        ? ValueListenableBuilder<bool>(
      valueListenable: _loading,
      builder: (context, loading, child) =>
      loading
          ? (widget.progressWidget ?? const CircularProgressIndicator())
          : widget.child,
    )
        : widget.child;
  }

  @override
  void onLoad(BuildContext context) {
    if (widget.config.hostCheck) {
      context.http
          .post(
        SimpleRequest(
          666,
          isPublic: true,
          needCredentials: false,
          customUrl: widget.config.host,
        ),
        showProgress: false,
        showRetry: false,
        ignoreExpireTime: true,
        requestTimeout: const Duration(seconds: 10),
      )
          .then((response) {
        if (response.data != null && response.success == 1) {
          currentHost = response.containsKey('host') && response['host'] != null
              ? response['host'].toString()
              : widget.config.host;
          _loading.value = false;
        }
      });
    }
  }
}
