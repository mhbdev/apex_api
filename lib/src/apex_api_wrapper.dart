import 'package:apex_api/apex_api.dart';
import 'package:apex_api/src/clients/base_connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ApexApiWrapper extends StatelessWidget {
  final ApiConfig config;
  final Widget child;
  final GlobalKey<NavigatorState> navKey;
  final OnMessage? onMessage;
  final OnLoginStepChanged? onLoginStepChanged;
  final Map<Type, ResType>? responseModels;
  final Widget? progressWidget;
  final OnRetry? onRetry;
  final bool useSocket;

  /// If you want to check the host availability in background set this to true otherwise
  /// [progressWidget] will be used as a placeholder until the best host be selected!
  final bool checkHostsInBackground;

  const ApexApiWrapper({
    Key? key,
    required this.config,
    required this.child,
    required this.navKey,
    this.onMessage,
    this.onLoginStepChanged,
    this.responseModels,
    this.progressWidget,
    this.onRetry,
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
            messageHandler: (request, response) {
              if (onMessage != null) {
                onMessage!(request, response);
              }
            },
            loginStepHandler: onLoginStepChanged,
            responseModels: responseModels,
            onRetry: onRetry,
            // retryBuilder: (context, retry) {
            //   if (onRetry != null) {
            //     onRetry!(retry);
            //   }
            //   return PopScope(
            //     canPop: true,
            //     child: CupertinoAlertDialog(
            //       // elevation: 1.0,
            //       title: const Text('Something went wrong!',
            //           style: TextStyle(
            //               color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
            //       content: const Text(
            //         'Connection error occurred',
            //         style: TextStyle(fontFamily: 'Vazir'),
            //       ),
            //       actions: <Widget>[
            //         CupertinoDialogAction(
            //           onPressed: () {
            //             Navigator.of(context, rootNavigator: true).pop();
            //             retry();
            //           },
            //           child: const Text(
            //             'Retry',
            //             style: TextStyle(fontFamily: 'Vazir'),
            //           ),
            //         ),
            //         CupertinoDialogAction(
            //           onPressed: () {
            //             Navigator.of(context, rootNavigator: true).pop();
            //           },
            //           child: const Text(
            //             'Cancel',
            //             style: TextStyle(fontFamily: 'Vazir'),
            //           ),
            //         ),
            //       ],
            //     ),
            //   );
            // },
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => useSocket
              ? BaseConnection.socket(config)
              : BaseConnection.http(
                  config,
                  onLoginStepChanged: onLoginStepChanged,
                  onMessage: onMessage,
                  onRetry: onRetry,
                  responseModels: responseModels,
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
    required this.child,
    required this.config,
    this.checkHostsInBackground = true,
    this.progressWidget,
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
            builder: (context, loading, child) => loading
                ? (widget.progressWidget ?? const CircularProgressIndicator())
                : widget.child,
          )
        : Consumer<BaseConnection>(
            builder: (context, baseConnection, child) => Stack(
              children: [
                Positioned.fill(
                    child: IgnorePointer(
                  ignoring: baseConnection.isShowingProgress,
                  child: widget.child,
                )),
                if (baseConnection.isShowingProgress)
                  Positioned.fill(
                    child: Center(
                      child: widget.progressWidget ?? const CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
  }

  @override
  void onLoad(BuildContext context) {
    if (widget.config.hostCheck) {
      context.connection
          .send(
        ApiAction(SimpleRequest(
          666,
          isPublic: true,
          needCredentials: false,
          customUrl: widget.config.host,
        )),
        showLoading: false,
        showRetry: false,
        ignoreExpireTime: true,
        requestTimeout: const Duration(seconds: 20),
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
