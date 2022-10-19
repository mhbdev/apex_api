import 'dart:async';
import 'dart:convert';
import 'package:apex_api/apex_api.dart';
import 'package:apex_api/src/exceptions/server_error_exception.dart';
import 'package:apex_api/src/exceptions/unauthorized_exception.dart';
import 'package:apex_api/src/preferences/storage_util.dart';
import 'package:crypto/crypto.dart';
import 'package:fingerprintjs/fingerprintjs.dart';
import 'package:flutter/foundation.dart';

class Api extends Equatable {
  Api({
    required this.config,
    required Map<Type, ResType> responseModels,
  }) {
    models = {Response: (x) => Response.fromJson(x), ...responseModels};
    connector =
        config.useSocket ? ApexSocket(config, models) : Http(config, models);
  }

  factory Api.socket(
      {required ApiConfig config, required Map<Type, ResType> responseModels}) {
    return Api(
        config: config.copyWith(useSocket: true),
        responseModels: responseModels);
  }

  factory Api.http(
      {required ApiConfig config, required Map<Type, ResType> responseModels}) {
    return Api(
        config: config.copyWith(useSocket: false),
        responseModels: responseModels);
  }

  final ApiConfig config;
  late final Connector connector;
  late final Map<Type, ResType> models;

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

  /// used to call action and send request
  Future<Res> request<Res extends Response>(
    Request request, {
    String languageCode = 'EN',
    bool? showProgress,
    bool? showRetry,
    VoidCallback? onStart,
    OnSuccess<Res>? onSuccess,
    OnConnectionError? onError,
    LoginStepManager? manageLoginStep,
    bool ignoreExpireTime = false,
  }) async {
    assert(languageCode.length == 2);
    assert(models.containsKey(Res),
        'You should define $Res in Apex responseModels');

    if (config.useMocks == false) {
      if (!request.isPublic &&
          request.needCredentials &&
          !ApexApiDb.isAuthenticated) {
        return Future.error(UnauthorisedException(
            'User not logged in and connection is private and user needs credentials : action ($Res - ${request.action})'));
      }
    } else {
      final response = models[Res]!(await request.responseMock) as Res;
      connector.handleMessage(response);
      return response;
    }

    String? fingerprint = ApexApiDb.getFingerprint();
    if (fingerprint == null) {
      fingerprint = await Fingerprint.getHash();
      ApexApiDb.setFingerprint(fingerprint);
    }

    final imei = ApexApiDb.getImei();
    final imsi = ApexApiDb.getImsi();
    request.addParams({
      'additional': {
        if (imei != null) 'imei': imei,
        if (imsi != null) 'imsi': imsi
      },
      'fingerprint': fingerprint,
      'language': languageCode.toUpperCase(),
      if (ApexApiDb.isAuthenticated && !request.containsKey('token') && ![1001, 1002, 1003, 1004].contains(request.action)) 'token': ApexApiDb.getToken(),
    });

    // try to load action from storage if action has been saved and not expired
    final storageKey = md5
        .convert(utf8.encode(
            'R_${request.action}${ApexApiDb.isAuthenticated && !request.isPublic ? (ApexApiDb.getToken() ?? '') : ''}'))
        .toString();
    if (!ignoreExpireTime) {
      final storage = StorageUtil.getString(storageKey);
      if (storage != null) {
        final result = jsonDecode(storage);
        final isExpired =
            DateTime.now().millisecondsSinceEpoch > (result['expires_at'] ?? 0);
        if (!isExpired) {
          if (config.debugMode) {
            if (kDebugMode) {
              print('Pre-loading $Res');
            }
          }
          // Can use local storage saved data
          final response = models[Res]!(result ?? {}) as Res;
          if (onSuccess != null) onSuccess(response);
          return response;
        } else {
          if (config.debugMode) {
            if (kDebugMode) {
              print('Could not preload $Res');
            }
          }
        }
      }
    }

    // could not preload the response from storage so make a new call to connector which is 'socket' or 'http'
    try {
      final response = await connector.send<Res>(request,
          showProgress: showProgress, showRetry: showRetry, onStart: onStart);

      if (response.hasData) {
        if (manageLoginStep != null) {
          if (response.success < 0 &&
              ![1001, 1002, 1003, 1004].contains(request.action)) {
            manageLoginStep(response.loginStep);
          }
        }
      }

      // save response to storage if it has save_local_duration parameter
      if (response.hasData &&
          response.containsKey('save_local_duration') &&
          response.data!['save_local_duration'] > 0) {
        StorageUtil.putString(
          storageKey,
          jsonEncode(<String, dynamic>{
            ...(response.data ?? {}),
            'expires_at': response.expiresAt
          }),
        );
      }

      if (onSuccess != null) onSuccess(response);

      return response;
    } catch (error, stackTrace) {
      if (onError != null) {
        onError(ServerErrorException('Something went wrong!'), error);
      }
      return Future.error(error, stackTrace);
    }
  }

  Future<Res> subscribePublic<Res extends Response>(String event) {
    assert(connector is ApexSocket);

    Completer<Res> completer = Completer();
    (connector as ApexSocket).socket.on(event, (data) {
      try {
        final json = jsonDecode(data);
        if (!completer.isCompleted) {
          completer.complete(models[Res]!(json) as Res);
        }
      } on FormatException {
        completer.completeError(
            ServerErrorException('Could not parse server response!'));
      }
    });
    return completer.future;
  }

  Future<dynamic> unsubscribePublic(String event) {
    assert(connector is ApexSocket);

    Completer<dynamic> completer = Completer();
    try {
      (connector as ApexSocket)
          .socket
          .off(event, (data) => completer.complete(data));
    } catch (e, s) {
      completer.completeError(e, s);
    }
    return completer.future;
  }

  Future<bool> join<Res extends Response>(JoinGroupRequest joinRequest,
      {VoidCallback? onStart,
      StreamSocket<Res>? stream,
      SocketJoinController<Res>? controller,
      void Function(Res res)? onListen,
      bool? showProgress,
      bool? showRetry,
      LoginStepManager? loginStepManager}) async {
    assert(connector is ApexSocket);

    final response = await request<Res>(joinRequest,
        onStart: onStart,
        showRetry: showRetry,
        showProgress: showProgress,
        manageLoginStep: loginStepManager);

    if (joinRequest.groupName != null) {
      if (response.hasData) {
        subscribePublic<Res>(
          response.data!['event_name'],
        ).then((data) {
          if (stream != null) stream.addResponse(data);
          if (controller != null) controller.onData(data);
          if (onListen != null) onListen(data);
        });

        if (stream != null) {
          stream.addListener((tag, [message]) {
            if (tag == 'closed') {
              (connector as ApexSocket)
                  .socket
                  .off(response.data!['event_name']);
            }
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
        return Future.error(
          response.error ??
              ServerErrorException('Could not join to desired groupName.'),
        );
      }
    }

    return response.success == 1;
  }

  Future<Res> uploadFile<Res extends Response>(
    Request request, {
    String? fileName,
    String fileKey = 'file',
    String? filePath,
    Uint8List? blobData,
    bool? showProgress,
    bool? showRetry,
    ValueChanged<double>? onProgress,
    ValueChanged<VoidCallback>? cancelToken,
  }) {
    return connector.uploadFile(
      request,
      fileName: fileName,
      fileKey: fileKey,
      filePath: filePath,
      showProgress: showProgress,
      showRetry: showRetry,
      blobData: blobData,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }

  @override
  List<Object?> get props => [config, connector];
}
