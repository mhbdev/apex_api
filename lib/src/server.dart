import 'dart:async';
import 'dart:convert';

import 'package:apex_api/apex_api.dart';
import 'package:apex_api/src/preferences/storage_util.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class Api extends Equatable {
  Api({
    required this.config,
    required Map<Type, ResType> responseModels,
  }) {
    models = {
      FetchProvinces: FetchProvinces.fromJson,
      DataModel: DataModel.fromJson,
      ...responseModels
    };
    connector = config.useSocket ? ApexSocket(config, models) : Http(config, models);
  }

  factory Api.socket({required ApiConfig config, required Map<Type, ResType> responseModels}) {
    return Api(config: config.copyWith(useSocket: true), responseModels: responseModels);
  }

  factory Api.http({required ApiConfig config, required Map<Type, ResType> responseModels}) {
    return Api(config: config.copyWith(useSocket: false), responseModels: responseModels);
  }

  final ApiConfig config;
  late final Connector connector;
  late final Map<Type, ResType> models;

  ConnectionStatus get status => (connector is ApexSocket)
      ? (connector as ApexSocket).status
      : (connector.isConnected ? ConnectionStatus.connected : ConnectionStatus.destroyed);

  bool get isReconnecting => status == ConnectionStatus.reconnecting;

  bool get errorOccurred => status == ConnectionStatus.error;

  bool get destroyed => status == ConnectionStatus.destroyed;

  bool get isConnecting => status == ConnectionStatus.connecting;

  bool get connected => status == ConnectionStatus.connected;

  /// used to call action and send request
  Future<BaseResponse<DM>> request<DM extends DataModel>(
    Request request, {
    String languageCode = 'EN',
    bool? showProgress,
    bool? showRetry,
    VoidCallback? onStart,
    OnSuccess<DM>? onSuccess,
    OnConnectionError? onError,
    LoginStepManager? manageLoginStep,
    bool ignoreExpireTime = false,
  }) async {
    assert(languageCode.length == 2);
    assert(models.containsKey(DM), 'You should define $DM in Apex responseModels');

    if (onStart != null) {
      onStart();
    }

    if (config.useMocks == false) {
      if (!request.isPublic && request.needCredentials && !ApexApiDb.isAuthenticated) {
        return Future.error(UnauthorisedException(
            'User not logged in and connection is private and user needs credentials : action ($DM - ${request.action})'));
      }
    } else {
      final response = BaseResponse(
        data: await request.responseMock,
        model: models[DM]!(await request.responseMock) as DM,
      );
      connector.handleMessage(response);
      await Future.delayed(const Duration(seconds: 2));
      if (onSuccess != null) {
        onSuccess(response);
      }
      return response;
    }

    String? fingerprint = ApexApiDb.getFingerprint();
    if (fingerprint == null) {
      // TODO : suitable exception is needed
      return Future.error(BadRequestException());
    }

    final imei = ApexApiDb.getImei();
    final imsi = ApexApiDb.getImsi();
    request.addParams({
      'additional': {if (imei != null) 'imei': imei, if (imsi != null) 'imsi': imsi},
      'fingerprint': fingerprint,
      'language': languageCode.toUpperCase(),
      if (ApexApiDb.isAuthenticated &&
          !request.containsKey('token') &&
          ![1001, 1002, 1003, 1004].contains(request.action))
        'token': ApexApiDb.getToken(),
    });

    // try to load action from storage if action has been saved and not expired
    if (config.debugMode) {
      if (kDebugMode) {
        print(
            'R_${config.appVersion}_${request.action}${ApexApiDb.isAuthenticated && !request.isPublic ? (ApexApiDb.getToken() ?? 'pr') : 'pu'}');
      }
    }
    final storageKey = md5
        .convert(utf8.encode(
            'R_${config.appVersion}_${request.action}${ApexApiDb.isAuthenticated && !request.isPublic ? (ApexApiDb.getToken() ?? 'pr') : 'pu'}'))
        .toString();
    if (!ignoreExpireTime) {
      //TODO : check it out => && DM is! Response) {
      final storage = StorageUtil.getString(storageKey);
      if (storage != null) {
        final result = jsonDecode(storage);
        final isExpired = DateTime.now().millisecondsSinceEpoch > (result['expires_at'] ?? 0);
        if (!isExpired) {
          if (config.debugMode) {
            debugPrint('Pre-loading $DM');
          }
          // Can use local storage saved data
          final response = BaseResponse(
            data: result,
            model: models[DM]!(result ?? {}) as DM,
          );
          if (onSuccess != null) onSuccess(response);
          return response;
        } else {
          if (config.debugMode) {
            debugPrint('Could not preload $DM');
          }
        }
      }
    }

    // could not preload the response from storage so make a new call to connector which is 'socket' or 'http'
    try {
      final response = await connector.send<DM>(
        request,
        showProgress: showProgress,
        showRetry: showRetry,
      );

      if (manageLoginStep != null) {
        if (response.success < 0 && ![1001, 1002, 1003, 1004].contains(request.action)) {
          manageLoginStep(response.loginStep);
        }
      }

      // save response to storage if it has save_local_duration parameter
      if (response.hasData &&
          response.containsKey('save_local_duration') &&
          response.data!['save_local_duration'] > 0) {
        StorageUtil.putString(
          storageKey,
          jsonEncode(<String, dynamic>{...(response.data ?? {}), 'expires_at': response.expiresAt}),
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

  Future<BaseResponse<DM>> subscribePublic<DM extends DataModel>(String event) {
    assert(connector is ApexSocket);

    Completer<BaseResponse<DM>> completer = Completer<BaseResponse<DM>>();
    (connector as ApexSocket).socket.on(event, (data) {
      try {
        final json = jsonDecode(data);
        if (!completer.isCompleted) {
          completer.complete(BaseResponse(data: json, model: models[DM]!(json) as DM));
        }
      } on FormatException {
        completer.completeError(ServerErrorException('Could not parse server response!'));
      }
    });
    return completer.future;
  }

  Future<dynamic> unsubscribePublic(String event) {
    assert(connector is ApexSocket);

    Completer<dynamic> completer = Completer();
    try {
      (connector as ApexSocket).socket.off(event, (data) => completer.complete(data));
    } catch (e, s) {
      completer.completeError(e, s);
    }
    return completer.future;
  }

  Future<bool> join<DM extends DataModel>(JoinGroupRequest joinRequest,
      {VoidCallback? onStart,
      StreamSocket<BaseResponse<DM>>? stream,
      SocketJoinController<BaseResponse<DM>>? controller,
      void Function(BaseResponse<DM> res)? onListen,
      bool? showProgress,
      bool? showRetry,
      LoginStepManager? loginStepManager}) async {
    assert(connector is ApexSocket);

    try {
      final response = await request<DM>(joinRequest,
          onStart: onStart,
          showRetry: showRetry,
          showProgress: showProgress,
          manageLoginStep: loginStepManager);

      if (joinRequest.groupName != null) {
        if (response.hasData) {
          subscribePublic<DM>(
            response.data!['event_name'],
          ).then((data) {
            if (stream != null) stream.addResponse(data);
            if (controller != null) controller.onData(data);
            if (onListen != null) onListen(data);
          });

          if (stream != null) {
            stream.addListener((tag, [message]) {
              if (tag == 'closed') {
                (connector as ApexSocket).socket.off(response.data!['event_name']);
              }
            });
          }

          if (controller != null) {
            controller.addListener((tag, [message]) {
              if (tag == joinRequest.groupName) {
                (connector as ApexSocket).socket.off(response.data!['event_name']);
              }
            });
          }
        } else {
          return Future.error(
            response.error ?? ServerErrorException('Could not join to desired groupName.'),
          );
        }
      }

      return response.success == 1;
    } catch (e) {
      rethrow;
    }
  }

  Future<BaseResponse<DM>> uploadFile<DM extends DataModel>(
    Request request, {
    String languageCode = 'EN',
    String? fileName,
    String fileKey = 'file',
    String? filePath,
    Uint8List? blobData,
    bool? showProgress,
    bool? showRetry,
    ValueChanged<double>? onProgress,
    ValueChanged<VoidCallback>? cancelToken,
    VoidCallback? onStart,
    OnSuccess<DM>? onSuccess,
    OnConnectionError? onError,
  }) async {
    String? fingerprint = ApexApiDb.getFingerprint();
    if (fingerprint == null) {
      // TODO : suitable exception is needed
      return Future.error(BadRequestException());
    }

    final imei = ApexApiDb.getImei();
    final imsi = ApexApiDb.getImsi();
    request.addParams({
      'additional': {if (imei != null) 'imei': imei, if (imsi != null) 'imsi': imsi},
      'fingerprint': fingerprint,
      'language': languageCode.toUpperCase(),
      if (ApexApiDb.isAuthenticated &&
          !request.containsKey('token') &&
          ![1001, 1002, 1003, 1004].contains(request.action))
        'token': ApexApiDb.getToken(),
    });

    return connector.uploadFile<DM>(
      request,
      fileName: fileName,
      fileKey: fileKey,
      filePath: filePath,
      showProgress: showProgress,
      showRetry: showRetry,
      blobData: blobData,
      cancelToken: cancelToken,
      onProgress: onProgress,
      onError: onError,
      onSuccess: onSuccess,
      onStart: onStart,
    );
  }

  @override
  List<Object?> get props => [config, connector];
}
