import 'dart:convert';

import 'package:apex_api/src/http/http.dart';
import 'package:apex_api/src/preferences/database.dart';
import 'package:flutter/foundation.dart';

import 'connector.dart';
import 'exceptions.dart';
import 'models/connection_config.dart';
import 'models/request.dart';
import 'models/response.dart';
import 'socket/socket.dart';
import 'socket_join_controller.dart';
import 'socket_stream.dart';
import 'typedefs.dart';

class Server {
  Server({
    required this.config,
    required this.responseModels,
  }) {
    connector = config.useSocket
        ? ApexSocket(config, responseModels)
        : Http(config, responseModels);
    connector.init();
  }

  final ConnectionConfig config;
  final Map<Type, ResType> responseModels;
  late final Connector connector;

  ConnectionStatus get status => (connector is ApexSocket)
      ? (connector as ApexSocket).status
      : (connector.isConnected
          ? ConnectionStatus.connected
          : ConnectionStatus.destroyed);

  bool get isReconnecting => status == ConnectionStatus.reconnecting;

  bool get errorOccurred => status == ConnectionStatus.error;

  bool get destroyed => status == ConnectionStatus.destroyed;

  bool get isConnecting => status == ConnectionStatus.connecting;

  bool get connected => status == ConnectionStatus.connected;

  String get statusMessage =>
      (status == ConnectionStatus.connected)
      ? 'connected'
      : (status != ConnectionStatus.reconnecting
          ? 'connectingIn_${(connector as ApexSocket).elapsed.toString()}'
          : 'connecting');

  // static void subscribe<Res extends ResponseModel>(StreamSocket socket) {}

  /// used to call action and send request
  Future<Res> request<Res extends ResponseModel>(
    Request request, {
    bool? showProgress,
    bool? showRetry,
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    assert(responseModels.containsKey(Res),
        'You should define $Res in Apex responseModels');

    if (!request.isPublic &&
        request.needCredentials &&
        !Database.isAuthenticated) {
      // if (onError != null) {
      //   onError(ConnectionError.authenticationError,
      //       'User not logged in and connection is private and user needs credentials : action (${request.action})');
      // }
      // if (config.onAuthError != null) config.onAuthError!(context);
      throw AuthenticationError(
          'User not logged in and connection is private and user needs credentials : action (${request.action})');
    }

    final requestMap = await request.toJson();
    requestMap.addAll({
      'additional': {},
      'fingerprint': Database.getFingerprint(),
      'language': 'en'
    });

    if (kDebugMode) {
      print(requestMap);
    }

    return connector.send<Res>(request);
  }

  void subscribePublic<Res extends Response>(
    String event,
    void Function(Res model) onSuccess,
    // {OnConnectionError? onError}
  ) {
    // debugPrint('Subscribed to $event');
    (connector as ApexSocket).socket.on(event, (data) {
      // debugPrint('listening $event => $data');
      try {
        final json = jsonDecode(data);
        onSuccess(responseModels[Res]!(json) as Res);
      } on FormatException catch (e) {
        // if (onError != null) onError(ConnectionError.parseResponseError, e);
      }
    });
  }

  void unsubscribePublic(String event) {
    // debugPrint('Unsubscribed from ' + event);
    (connector as ApexSocket).socket.off(event);
  }

  void join<Res extends Response>(
    JoinGroupRequest joinRequest, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    ValueChanged<bool>? onSuccess,
    // OnConnectionError? onError,
    StreamSocket<Res>? stream,
    SocketJoinController<Res>? controller,
    void Function(Res res)? onListen,
  }) {
    request<Res>(
      joinRequest,
      onComplete: onComplete,
      onStart: onStart,
    ).then((response) {
      if (onSuccess != null) {
        onSuccess(response.success == 1);
      }

      if (joinRequest.groupName != null) {
        // debugPrint('joined => ${model.data['event_name']} event');
        if (response.hasData) {
          subscribePublic<Res>(response.data!['event_name'], (data) {
            if (stream != null) {
              // if (joinRequest.groupName == 'PAIR_INFO') {
              //   debugPrint('GROUP_NAME: ${joinRequest.groupName}, $data');
              // }
              stream.addResponse(data);
            }

            if (controller != null) {
              controller.onData(data);
            }

            if (onListen != null) {
              onListen(data);
            }
          },);

          if (stream != null) {
            stream.addListener(() {
              // debugPrint(model.data['event_name'] + 'WE ARE SCREWED');
              (connector as ApexSocket).socket.off(response.data!['event_name']);
            });
          }

          if (controller != null) {
            controller.addListener((tag, [message]) {
              if (tag == joinRequest.groupName) {
                (connector as ApexSocket)
                    .socket
                    .off(response.data!['event_name']);
              }
            });
          }
        } else {
          // if (onError != null) {
          //   onError(ConnectionError.nullResponseError,
          //       ConnectionException('Server response is null!'),
          //       connection: connection);
          // }
        }
      }
    });
  }
}
