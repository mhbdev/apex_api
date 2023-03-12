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
      child: child,
    );
  }
}
