import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:apex_api/src/typedefs.dart';
import 'package:cancellation_token/cancellation_token.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../cipher/crypto.dart';
import '../../exceptions/exceptions.dart';
import '../../models/connection_config.dart';
import '../../models/default_requests/city_province.dart';
import '../../models/request.dart';
import '../../models/response.dart';
import '../../multipart_request.dart';
import '../../preferences/database.dart';
import '../../preferences/storage_util.dart';
import '../../socket_join_controller.dart';
import '../../socket_stream.dart';
import 'browser_client.dart' if (dart.library.html) 'package:http/browser_client.dart';

enum ConnectionStatus { reconnecting, connecting, connected, error, destroyed, timeout }

class HttpAlt extends ChangeNotifier {
  late io.Socket socket;
  http.Client? client;
  final ApiConfig config;
  final Logger logger;
  final GlobalKey<NavigatorState> navKey;
  final ValueChanged<LoginStep>? loginStepHandler;
  final void Function(Request request, BaseResponse response)? messageHandler;
  final Map<Type, ResType>? responseModels;
  final Widget? progressWidget;
  final Widget Function(BuildContext context, VoidCallback onRetry)? retryBuilder;
  final io.OptionBuilder options;
  final bool useSocket;

  bool get isConnected => socket.connected;

  bool isProgressShowing = false;
  bool isRetryShowing = false;
  bool isSocketInitialized = false;

  int delay = 1;
  int elapsed = 2;
  Timer? timer;
  ConnectionStatus status = ConnectionStatus.connecting;

  HttpAlt(
    this.config, {
    this.retryBuilder,
    this.progressWidget,
    this.messageHandler,
    this.loginStepHandler,
    this.useSocket = false,
    required this.navKey,
    http.Client? client,
    Map<Type, ResType>? responseModels,
  })  : assert(Uri.parse(config.host).isAbsolute, '${config.host} must be a valid url.'),
        assert(config.port == null || (config.port! >= -1 && config.port! <= 65535),
            '${config.port} must be a number between -1 and 65535. or null.'),
        responseModels = {
          FetchCountries: FetchCountries.fromJson,
          FetchProvinces: FetchProvinces.fromJson,
          DataModel: DataModel.fromJson,
          if (responseModels != null) ...responseModels,
        },
        logger = Logger(
          level: config.logLevel,
          filter: null, // Use the default LogFilter (-> only log in debug mode)
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            printTime: false,
          ),
          output: null, // Use the default LogOutput (-> send everything to console)
        ),
        client = client ??
            (kIsWeb
                ? BrowserClient()
                : IOClient(HttpClient()..connectionTimeout = config.connectionTimeout)),
        options = config.options ??
            io.OptionBuilder().disableAutoConnect().disableForceNew().disableForceNewConnection() {
    if (useSocket && !isSocketInitialized) {
      socket = io.io(
        '${config.host}${config.port != null ? ':${config.port}' : ''}/${config.namespace}',
        options.setTransports(['websocket']).build(),
      );

      connect();

      socket.onConnect((data) {
        status = ConnectionStatus.connected;
        _notifyStatus();
      });

      socket.onConnectError((data) {
        _reconnect();
        status = ConnectionStatus.error;
        _notifyStatus();
      });

      socket.onError((data) {
        _reconnect();
        status = ConnectionStatus.error;
        _notifyStatus();
      });

      socket.onDisconnect((data) {
        _reconnect();
        status = ConnectionStatus.destroyed;
        _notifyStatus();
      });

      socket.onReconnect((data) {
        status = ConnectionStatus.connecting;
        _notifyStatus();
      });

      socket.onReconnecting((data) {
        status = ConnectionStatus.connecting;
        _notifyStatus();
      });

      socket.onConnectTimeout((data) {
        status = ConnectionStatus.timeout;
        _notifyStatus();
      });

      isSocketInitialized = true;
    }
  }

  void _reconnect() {
    if (delay < 64) {
      delay *= 2;
    } else {
      delay = 1;
    }
    elapsed = delay;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (elapsed > 0) {
        elapsed--;
      } else {
        timer.cancel();
        connect();
        status = ConnectionStatus.reconnecting;
      }
      notifyListeners();
    });
  }

  void connectReset() {
    delay = 1;
    if (timer != null) {
      timer!.cancel();
    }
    connect();
    status = ConnectionStatus.reconnecting;
    _notifyStatus();
  }

  io.Socket connect({EventHandler? onConnect}) {
    socket.onConnect((data) {
      if (status != ConnectionStatus.connected) {
        status = ConnectionStatus.connected;
        _notifyStatus();
      }

      if (onConnect != null) {
        onConnect(data);
      }
    });

    if (!socket.connected) {
      socket.connect();
    }
    return socket;
  }

  void _notifyStatus() {
    notifyListeners();
  }

  Future<BaseResponse<T>> post<T extends DataModel>(
    Request request, {
    T Function(Json json)? response,
    VoidCallback? onStart,
    ValueChanged<BaseResponse<T>>? onSuccess,
    String? languageCode,
    bool showProgress = false,
    bool showRetry = false,
    Map<String, String>? headers,
    Encoding? encoding,
    bool ignoreExpireTime = false,
    Duration? requestTimeout,
    CancellationToken? cancellationToken,
  }) async {
    assert(languageCode == null || languageCode.length == 2);
    assert(response != null || responseModels?.containsKey(T) == true);

    if (client != null) {
      if (client is IOClient) {
        if (requestTimeout != null) {
          client = IOClient(HttpClient()..connectionTimeout = requestTimeout);
        }
      }
    }

    Future<BaseResponse<T>> retryClosure() => post<T>(
          request,
          response: response,
          languageCode: languageCode,
          ignoreExpireTime: ignoreExpireTime,
          showRetry: showRetry,
          onStart: onStart,
          headers: headers,
          encoding: encoding,
          onSuccess: onSuccess,
          showProgress: showProgress,
          requestTimeout: requestTimeout,
          cancellationToken: cancellationToken,
        );

    if (onStart != null) onStart();
    _showProgress(showProgress);

    if (config.useMocks == false) {
      if (!request.isPublic && request.needCredentials && !ApexApiDb.isAuthenticated) {
        logger.w(
            'User not logged in and connection is private and user needs credentials : action (${request.action})');
        return BaseResponse(
            error: UnauthorisedException(
                'User not logged in and connection is private and user needs credentials : action (${request.action})'));
      }
    } else {
      final res = BaseResponse<T>(
        data: await request.responseMock,
        model: response != null
            ? response(await request.responseMock)
            : (responseModels != null && responseModels!.containsKey(T)
                ? responseModels![T]!(await request.responseMock) as T
                : null),
      );
      await Future.delayed(const Duration(seconds: 2));
      _hideProgress(showProgress);
      _handleMessage(request, res);
      _handleLoginStep(request, res);
      if (onSuccess != null) onSuccess(res);
      return res;
    }

    String? fingerprint = ApexApiDb.getFingerprint();
    if (fingerprint == null) {
      return BaseResponse(error: UnauthorisedException('Could not find user\'s fingerprint!'));
    }

    final imei = ApexApiDb.getImei();
    final imsi = ApexApiDb.getImsi();
    final additional = ApexApiDb.getAdditional();
    request.addParams({
      if ([1001, 1002, 1003, 1004].contains(request.action)) ...{
        'additional': {
          if (imei != null) 'imei': imei,
          if (imsi != null) 'imsi': imsi,
          if (additional != null) ...additional,
        },
        if (config.handlerNamespace != null) 'namespace': config.handlerNamespace,
      },
      'fingerprint': fingerprint,
      'language': (languageCode ?? config.languageCode).toUpperCase(),
      if (ApexApiDb.isAuthenticated &&
          !request.containsKey('token') &&
          ![1001, 1002, 1003, 1004].contains(request.action))
        'token': ApexApiDb.getToken(),
    });

    // Try to load action from storage if action has been saved and not expired
    final storageKey = md5
        .convert(utf8.encode(
            'R_${request.storageUniqueKey != null ? request.storageUniqueKey! : ''}${config.dbVersion}_${request.action}${ApexApiDb.isAuthenticated && !request.isPublic ? (ApexApiDb.getToken() ?? 'pr') : 'pu'}'))
        .toString();
    if (!ignoreExpireTime) {
      final storage = StorageUtil.getString(storageKey);
      if (storage != null) {
        try {
          final result = jsonDecode(storage);
          final isExpired = DateTime.now().millisecondsSinceEpoch > (result['expires_at'] ?? 0);
          if (!isExpired) {
            logger.i(
                'Pre-loading ${request.isPrivate ? 'Private' : 'Public'} action ${request.action}:${response != null ? response.runtimeType : T}');
            // We can use local storage saved data
            final res = BaseResponse<T>(
              data: result,
              model: response != null
                  ? response(result ?? {'success': -1})
                  : (responseModels != null && responseModels!.containsKey(T)
                      ? responseModels![T]!(result ?? {'success': -1}) as T
                      : null),
            );
            if (onSuccess != null) onSuccess(res);
            return res;
          } else {
            logger.i(
                'Could not preload ${response.runtimeType}, Therefore the response is being removed for the next api call.');
            StorageUtil.remove(storageKey);
          }
        } on FormatException {
          logger.e('Could Not Parse saved response!');
          return BaseResponse(error: ResponseParseException());
        }
      }
    }

    // Could not preload the response from storage so make a new call
    final crypto = Crypto(config.secretKey, config.publicKey);

    final String url = request.handlerUrl ?? (currentHost ?? config.host);

    logger.i(
        '[$url]: Request (${request.action}-${request.isPrivate ? 'PR' : 'PU'}-$T): ${await request.toJson()}');
    String requestMessage = await _encrypt(crypto, request);

    BaseResponse<T>? res;
    ServerException? exception;
    try {
      var requestBody = jsonEncode({
        'os': config.os,
        'private': (request.isPrivate ? 1 : 0),
        'version': (request.isPrivate ? config.privateVersion : config.publicVersion),
        config.namespace: requestMessage
      });

      var gzip = GZipCodec();

      http.Response httpResponse = await (client != null
          ? client!
              .post(
                Uri.parse(url),
                headers: headers,
                body: config.enableGzip
                    ? gzip.encode(requestBody.codeUnits)
                    : {'request': requestBody},
                encoding: encoding ?? Encoding.getByName('utf-8'),
              )
              .timeout(requestTimeout ?? config.requestTimeout, onTimeout: config.onTimeout)
              .asCancellable(cancellationToken)
          : http
              .post(
                Uri.parse(url),
                headers: headers,
                body: config.enableGzip
                    ? gzip.encode(requestBody.codeUnits)
                    : {'request': requestBody},
                encoding: encoding ?? Encoding.getByName('utf-8'),
              )
              .timeout(requestTimeout ?? config.requestTimeout, onTimeout: config.onTimeout)
              .asCancellable(cancellationToken));

      if (httpResponse.statusCode == 200) {
        String responseMessage;
        if (((request.encrypt ?? false) || (config.encrypt))) {
          responseMessage = httpResponse.body.trim();
        } else {
          responseMessage = httpResponse.body;
        }

        responseMessage = _decrypt(crypto, request, responseMessage);

        logger.i(
            'Response (${request.action}-${request.isPrivate ? 'PR' : 'PU'}-$T): $responseMessage');

        final decodedResponse = jsonDecode(responseMessage);
        res = BaseResponse<T>(
          data: decodedResponse,
          model: response != null
              ? response(decodedResponse)
              : (responseModels != null && responseModels!.containsKey(T)
                  ? responseModels![T]!(decodedResponse) as T
                  : null),
        );

        // Save response to storage if it has save_local_duration parameter
        if (res.hasData &&
            res.containsKey('save_local_duration') &&
            res.data!['save_local_duration'] > 0) {
          StorageUtil.putString(
            storageKey,
            jsonEncode(<String, dynamic>{...(res.data ?? {}), 'expires_at': res.expiresAt}),
          );
        }
        _hideProgress(showProgress);

        if (onSuccess != null) onSuccess(res);
        return res;
      } else {
        logger.e('Status Code: ${httpResponse.statusCode}');
        exception = ServerErrorException('Response status code is ${httpResponse.statusCode}');
      }
    } on CancelledException catch (e, stackTrace) {
      logger.i('Cancelled using a token', e, stackTrace);
      exception = ClientErrorException('Cancelled using a token');
    } on FormatException catch (e, stackTrace) {
      logger.e('Could not resolve json format parsing!', e, stackTrace);
      exception = ResponseParseException();
    } on http.ClientException catch (e, stackTrace) {
      logger.e('A ClientException has been occurred', e, stackTrace);
      exception = ClientErrorException();
    } on SocketException catch (e, stackTrace) {
      logger.e('A Network Error has been thrown!', e, stackTrace);
      exception = NetworkErrorException();
    } catch (e, stackTrace) {
      logger.e('Something happened during sending http post request!', e, stackTrace);
      exception = ServerErrorException();
    } finally {
      _hideProgress(showProgress);
      if (res != null) {
        _handleMessage(request, res);
        _handleLoginStep(request, res);
      }
    }

    return _handleRetry<T>(showRetry, retryClosure,
        BaseResponse<T>(error: exception, errorMessage: exception.message));
  }

  Future<BaseResponse<T>> emit<T extends DataModel>(
    Request request, {
    T Function(Json json)? response,
    VoidCallback? onStart,
    ValueChanged<BaseResponse<T>>? onSuccess,
    OnConnectionError? onError,
    String? languageCode,
    bool showProgress = false,
    bool showRetry = false,
    Map<String, String>? headers,
    Encoding? encoding,
    bool ignoreExpireTime = false,
  }) async {
    assert(config.port != null, 'You have to provide a port like 443');
    assert(languageCode == null || languageCode.length == 2);
    assert(response != null || responseModels?.containsKey(T) == true);

    Future<BaseResponse<T>> retryClosure() => emit<T>(
      request,
          response: response,
          languageCode: languageCode,
          ignoreExpireTime: ignoreExpireTime,
          showRetry: showRetry,
          onStart: onStart,
          headers: headers,
          encoding: encoding,
          onSuccess: onSuccess,
          onError: onError,
          showProgress: showProgress,
        );

    if (onStart != null) onStart();
    _showProgress(showProgress);

    if (config.useMocks == false) {
      if (!request.isPublic && request.needCredentials && !ApexApiDb.isAuthenticated) {
        logger.w(
            'User not logged in and connection is private and user needs credentials : action (${request.action})');
        return BaseResponse(
            error: UnauthorisedException(
                'User not logged in and connection is private and user needs credentials : action (${request.action})'));
      }
    } else {
      final res = BaseResponse<T>(
        data: await request.responseMock,
        model: response != null
            ? response(await request.responseMock)
            : (responseModels != null && responseModels!.containsKey(T)
                ? responseModels![T]!(await request.responseMock) as T
                : null),
      );
      _hideProgress(showProgress);
      _handleMessage(request, res);
      _handleLoginStep(request, res);
      await Future.delayed(const Duration(seconds: 2));
      if (onSuccess != null) onSuccess(res);
      return res;
    }

    String? fingerprint = ApexApiDb.getFingerprint();
    if (fingerprint == null) {
      return BaseResponse(error: UnauthorisedException('Could not find user\'s fingerprint!'));
    }

    final imei = ApexApiDb.getImei();
    final imsi = ApexApiDb.getImsi();
    final additional = ApexApiDb.getAdditional();
    request.addParams({
      if ([1001, 1002, 1003, 1004].contains(request.action)) ...{
        'additional': {
          if (imei != null) 'imei': imei,
          if (imsi != null) 'imsi': imsi,
          if (additional != null) ...additional,
        },
        if (config.handlerNamespace != null) 'namespace': config.handlerNamespace,
      },
      'fingerprint': fingerprint,
      'language': (languageCode ?? config.languageCode).toUpperCase(),
      if (ApexApiDb.isAuthenticated &&
          !request.containsKey('token') &&
          ![1001, 1002, 1003, 1004].contains(request.action))
        'token': ApexApiDb.getToken(),
    });

    // Try to load action from storage if action has been saved and not expired
    final storageKey = md5
        .convert(utf8.encode(
            'R_${request.storageUniqueKey != null ? request.storageUniqueKey! : ''}${config.dbVersion}_${request.action}${ApexApiDb.isAuthenticated && !request.isPublic ? (ApexApiDb.getToken() ?? 'pr') : 'pu'}'))
        .toString();
    if (!ignoreExpireTime) {
      final storage = StorageUtil.getString(storageKey);
      if (storage != null) {
        try {
          final result = jsonDecode(storage);
          final isExpired = DateTime.now().millisecondsSinceEpoch > (result['expires_at'] ?? 0);
          if (!isExpired) {
            logger.i(
                'Pre-loading ${request.isPrivate ? 'Private' : 'Public'} action ${request.action}:${response != null ? response.runtimeType : T}');
            // We can use local storage saved data
            final res = BaseResponse<T>(
              data: result,
              model: response != null
                  ? response(result ?? {'success': -1})
                  : (responseModels != null && responseModels!.containsKey(T)
                      ? responseModels![T]!(result ?? {'success': -1}) as T
                      : null),
            );
            if (onSuccess != null) onSuccess(res);
            logger.i(res.toString());
            return res;
          } else {
            logger.i(
                'Could not preload ${response.runtimeType}, Therefore the response is being removed for the next api call.');
            StorageUtil.remove(storageKey);
          }
        } on FormatException {
          logger.e('Could Not Parse saved response!');
          return BaseResponse(error: ResponseParseException());
        }
      }
    }

    // Could not preload the response from storage so make a new call
    final crypto = Crypto(config.secretKey, config.publicKey);
    logger.i('Request: ${await request.toJson()}');
    String requestMessage = await _encrypt(crypto, request);

    BaseResponse<T>? res;
    ServerException? exception;

    try {
      // final String url = request.handlerUrl ?? config.host;
      var requestBody = jsonEncode({
        'os': config.os,
        'private': (request.isPrivate ? 1 : 0),
        'version': (request.isPrivate ? config.privateVersion : config.publicVersion),
        'data': requestMessage
      });

      res = await emitWithFutureAck<T>(
          crypto, request, requestBody, response, storageKey, onSuccess, onError, showProgress);
    } on FormatException catch (e, stackTrace) {
      logger.e('Could not resolve json format parsing!', e, stackTrace);
      exception = ResponseParseException();
    } on http.ClientException catch (e, stackTrace) {
      logger.e('A ClientException has been occurred', e, stackTrace);
      exception = ClientErrorException();
    } on SocketException catch (e, stackTrace) {
      logger.e('A Network Error has been thrown!', e, stackTrace);
      exception = NetworkErrorException();
    } catch (e, stackTrace) {
      logger.e('Something happened during sending http post request!', e, stackTrace);
      exception = ServerErrorException();
    } finally {
      _hideProgress(showProgress);
      if (res != null) {
        _handleMessage(request, res);
        _handleLoginStep(request, res);
      }
    }

    return _handleRetry<T>(showRetry, retryClosure, BaseResponse<T>(error: exception));
  }

  Future<BaseResponse<DM>> subscribePublic<DM extends DataModel>(String event,
      [OnSuccess<DM>? onSuccess]) {
    Completer<BaseResponse<DM>> completer = Completer<BaseResponse<DM>>();
    socket.on(event, (data) {
      try {
        final json = jsonDecode(data);
        if (!completer.isCompleted) {
          final res = BaseResponse(data: json, model: responseModels![DM]!(json) as DM);
          if (onSuccess != null) {
            onSuccess(res);
          }
          completer.complete(res);
        }
      } on FormatException {
        completer.completeError(ServerErrorException('Could not parse server response!'));
      } catch (e) {
        completer.completeError(ServerErrorException('Something went wrong $e'));
      }
    });
    return completer.future;
  }

  Future<dynamic> unsubscribePublic(String event) {
    Completer<dynamic> completer = Completer();
    try {
      socket.off(event, (data) => completer.complete(data));
    } catch (e, s) {
      completer.completeError(e, s);
    }
    return completer.future;
  }

  Future<bool> join<DM extends DataModel>(
    JoinGroupRequest joinRequest, {
    VoidCallback? onStart,
    StreamSocket<BaseResponse<DM>>? stream,
    SocketJoinController<BaseResponse<DM>>? controller,
    void Function(BaseResponse<DM> res)? onListen,
    bool showProgress = false,
    bool showRetry = false,
  }) async {
    try {
      final response = await emit<DM>(
        joinRequest,
        onStart: onStart,
        showRetry: showRetry,
        showProgress: showProgress,
      );

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
                socket.off(response.data!['event_name']);
              }
            });
          }

          if (controller != null) {
            controller.addListener((tag, [message]) {
              if (tag == joinRequest.groupName) {
                socket.off(response.data!['event_name']);
              }
            });
          }
        } else {
          return Future.error(
            response.error ?? ServerErrorException('Could not join to desired groupName.'),
          );
        }
      }

      return response.isSuccessful;
    } catch (e) {
      rethrow;
    }
  }

  Future<BaseResponse<T>> uploadFile<T extends DataModel>(
    Request request, {
    String? fileName,
    String fileKey = 'file',
    String? filePath,
    Uint8List? blobData,
    T Function(Json json)? response,
    VoidCallback? onStart,
    String? languageCode,
    ValueChanged<double>? onProgress,
    ValueChanged<VoidCallback>? cancelToken,
    bool showProgress = false,
    bool showRetry = false,
    ValueChanged<BaseResponse<T>>? onSuccess,
    Map<String, String>? headers,
    Encoding? encoding,
    bool ignoreExpireTime = false,
  }) async {
    assert(languageCode == null || languageCode.length == 2);
    assert(response != null || responseModels?.containsKey(T) == true,
        'Provide a [response] or add your response parser to [responseModels] in ApiWrapper');
    if (onStart != null) onStart();

    Future<BaseResponse<T>> retryClosure() => uploadFile<T>(
          request,
          response: response,
          languageCode: languageCode,
          ignoreExpireTime: ignoreExpireTime,
          showRetry: showRetry,
          onStart: onStart,
          headers: headers,
          encoding: encoding,
          onSuccess: onSuccess,
          showProgress: showProgress,
          filePath: filePath,
          fileName: fileName,
          blobData: blobData,
          onProgress: onProgress,
          cancelToken: cancelToken,
          fileKey: fileKey,
        );

    _showProgress(showProgress);

    String? fingerprint = ApexApiDb.getFingerprint();
    if (fingerprint == null) {
      return BaseResponse(error: UnauthorisedException('Could not find user\'s fingerprint!'));
    }

    final imei = ApexApiDb.getImei();
    final imsi = ApexApiDb.getImsi();
    final additional = ApexApiDb.getAdditional();
    request.addParams({
      if ([1001, 1002, 1003, 1004].contains(request.action)) ...{
        'additional': {
          if (imei != null) 'imei': imei,
          if (imsi != null) 'imsi': imsi,
          if (additional != null) ...additional,
        },
        'namespace': config.handlerNamespace,
      },
      'fingerprint': fingerprint,
      'language': (languageCode ?? config.languageCode).toUpperCase(),
      if (ApexApiDb.isAuthenticated &&
          !request.containsKey('token') &&
          ![1001, 1002, 1003, 1004].contains(request.action))
        'token': ApexApiDb.getToken(),
    });

    var req = FileRequest(
      request.method.name,
      Uri.parse(request.handlerUrl ?? (currentHost ?? config.host)),
      (bytes, totalBytes) {
        if (onProgress != null) onProgress(bytes / totalBytes);
      },
      config.connectionTimeout,
    );

    if (blobData != null) {
      req.files.add(http.MultipartFile.fromBytes(fileKey, blobData,
          contentType: MediaType('application', 'octet-stream'), filename: fileName));
    }

    if (filePath != null) {
      req.files.add(await http.MultipartFile.fromPath(fileKey, filePath));
    }

    final crypto = Crypto(config.secretKey, config.publicKey);
    logger.i('Request: ${await request.toJson()}');
    String requestMessage = await _encrypt(crypto, request);

    req.fields['request'] = jsonEncode({
      'os': config.os,
      'version': request.isPublic ? config.publicVersion : config.privateVersion,
      'private': request.isPublic ? 0 : 1,
      config.namespace: requestMessage
    });
    if (cancelToken != null) cancelToken(req.close);

    ServerException? exception;
    try {
      var uploadResponse = await req.send().timeout(config.uploadTimeout);

      _hideProgress(showProgress);

      if (uploadResponse.statusCode == 200) {
        var responseBody = await uploadResponse.stream.bytesToString();
        responseBody = _decrypt(crypto, request, responseBody);

        try {
          var jsonResponse = jsonDecode(responseBody);
          final res = BaseResponse(
            data: jsonResponse,
            model: response != null
                ? response(jsonResponse)
                : (responseModels != null ? responseModels![T]!(jsonResponse) as T : null),
          );
          if (onSuccess != null) onSuccess(res);
          _handleMessage(request, res);
          return res;
        } on FormatException catch (e, stackTrace) {
          logger.e('Response Parse Error!', e, stackTrace);
          exception = ResponseParseException('Could not parse server uploadResponse! wanna retry?');
        }
      } else {
        logger.e('Status Code: ${uploadResponse.statusCode}');
        exception = ServerException(
            message: 'Could not parse server uploadResponse!',
            code: uploadResponse.statusCode.toString());
      }
    } catch (e) {
      _hideProgress(showProgress);
      exception = ServerException(message: 'Could not receive server uploadResponse!', code: '-1');
    }

    return _handleRetry(showRetry, retryClosure, BaseResponse(error: exception));
  }

  Future<String> _encrypt(Crypto crypto, Request request) async {
    String formattedRequest = jsonEncode(await request.toJson());

    if (request.isPublic) {
      return base64Encode(utf8.encode(formattedRequest));
    }

    if (request.encrypt == false) {
      return formattedRequest;
    }

    return crypto.encrypt(formattedRequest);
  }

  String _decrypt(Crypto crypto, Request request, String responseMessage) {
    if (request.encrypt == false || request.isPublic) {
      return responseMessage;
    }

    return crypto.decrypt(responseMessage);
  }

  void _showProgress(bool showProgress) async {
    if (showProgress) {
      if (!isProgressShowing) {
        if (navKey.currentContext != null) {
          isProgressShowing = true;
          await showDialog(
            context: navKey.currentContext!,
            barrierDismissible: false,
            useRootNavigator: true,
            builder: (context) =>
            progressWidget ??
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const CircularProgressIndicator(),
                  ),
                ),
          );
        }
      }
    }
  }

  void _hideProgress(bool showProgress) {
    if (showProgress) {
      if (isProgressShowing) {
        if (navKey.currentContext != null) {
          isProgressShowing = false;
          Navigator.of(navKey.currentContext!, rootNavigator: true).pop();
        }
      }
    }
  }

  void _handleMessage(Request request, BaseResponse response) {
    if (messageHandler != null) {
      messageHandler!(request, response);
    }
  }

  void _handleLoginStep(Request request, BaseResponse res) {
    if (res.success < 0 && ![1001, 1002, 1003, 1004].contains(request.action)) {
      if (loginStepHandler != null) {
        loginStepHandler!(res.loginStep);
      }
    }
  }

  Future<BaseResponse<T>> _handleRetry<T extends DataModel>(bool showRetry,
      Future<BaseResponse<T>> Function() retryClosure, BaseResponse<T> placeholder) async {
    Completer<BaseResponse<T>> completer = Completer<BaseResponse<T>>();
    if (showRetry && retryBuilder != null) {
      if (!isRetryShowing) {
        await showDialog(
          context: navKey.currentContext!,
          barrierDismissible: false,
          builder: (context) => retryBuilder!(context, () {
            completer.complete(retryClosure());
          }),
        );
        if (!completer.isCompleted) {
          completer.completeError('Could Not Complete Retry Cycle!');
        }
      }
    } else {
      completer.complete(placeholder);
    }
    return completer.future;
  }

  Future<BaseResponse<T>> emitWithFutureAck<T extends DataModel>(crypto, request, requestBody,
      response, storageKey, onSuccess, OnConnectionError? onError, showProgress) {
    Completer<BaseResponse<T>> completer = Completer<BaseResponse<T>>();

    socket.emitWithAck(config.eventName, requestBody, ack: (m) {
      BaseResponse<T>? res;
      try {
        m = m.toString();
        String responseMessage = m;
        if (((request.encrypt ?? false) || (config.encrypt))) {
          responseMessage = m.trim();
        }

        responseMessage = _decrypt(crypto, request, responseMessage);

        logger.i('Response: $responseMessage');

        final decodedResponse = jsonDecode(responseMessage);
        res = BaseResponse<T>(
          data: decodedResponse,
          model: response != null
              ? response(decodedResponse)
              : (responseModels != null && responseModels!.containsKey(T)
                  ? responseModels![T]!(decodedResponse) as T
                  : null),
        );

        // Save response to storage if it has save_local_duration parameter
        if (res.hasData &&
            res.containsKey('save_local_duration') &&
            res.data!['save_local_duration'] > 0) {
          StorageUtil.putString(
            storageKey,
            jsonEncode(<String, dynamic>{...(res.data ?? {}), 'expires_at': res.expiresAt}),
          );
        }
        _hideProgress(showProgress);
        if (onSuccess != null) onSuccess(res);
      } on FormatException catch (e, stackTrace) {
        logger.e('Response Parse Error!', e, stackTrace);
        if (!completer.isCompleted) {
          completer.complete(BaseResponse(
              error: ResponseParseException('Could not parse the response: $m'),
              errorMessage: 'Could not parse the response: $m'));
        }
        if (onError != null) {
          onError(ResponseParseException('Could not parse the response: $m'), e);
        }
      } catch (e) {
        if (onError != null) {
          onError(ServerErrorException(), e);
        }
        if (!completer.isCompleted) {
          completer.complete(BaseResponse(error: ServerErrorException()));
        }
      }
    });

    return completer.future;
  }
}
