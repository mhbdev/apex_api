import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../apex_api.dart';
import '../../cipher/crypto.dart';
import '../preferences/storage_util.dart';
import 'base_connection.dart';
import 'http/browser_client.dart' if (dart.library.html) 'package:http/browser_client.dart';

class HttpConnection extends BaseConnection {
  http.Client? client;

  HttpConnection(
    super.config, {
    super.onRetry,
    super.onMessage,
    super.onLoginStepChanged,
    super.responseModels,
    http.Client? client,
  }) : client = client ??
            (kIsWeb
                ? BrowserClient()
                : IOClient(HttpClient()..connectionTimeout = config.connectionTimeout));

  @override
  Future<BaseResponse<T>> send<T extends DataModel>(
    ApiAction<T> action, {
    VoidCallback? onStart,
    ValueChanged<BaseResponse<T>>? onSuccess,
    String? languageCode,
    bool showLoading = false,
    bool showRetry = false,
    Map<String, String>? headers,
    Encoding? encoding,
    bool ignoreExpireTime = false,
    Duration? requestTimeout,
    CancellationToken? cancellationToken,
    T Function(Json json)? response,
  }) async {
    assert(languageCode == null || languageCode.length == 2,
        'Language must me a 2 character symbol like FA or EN');
    assert(action.response != null || responseModels?.containsKey(T) == true,
        "No response parser available");

    if (client != null) {
      if (client is IOClient) {
        if (requestTimeout != null) {
          client = IOClient(HttpClient()..connectionTimeout = requestTimeout);
        }
      }
    }

    Future<BaseResponse<T>> retryClosure() => send<T>(
          action,
          languageCode: languageCode,
          ignoreExpireTime: ignoreExpireTime,
          showRetry: showRetry,
          onStart: onStart,
          headers: headers,
          encoding: encoding,
          onSuccess: onSuccess,
          showLoading: showLoading,
          requestTimeout: requestTimeout,
          cancellationToken: cancellationToken,
        );

    final request = action.request;
    final response = action.response ?? responseModels?[T];

    if (onStart != null) onStart();

    // Handling Progress
    if (showLoading) {
      showProgress();
    }

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
        model: response!(await request.responseMock) as T,
      );
      await Future.delayed(const Duration(seconds: 2));

      if (showLoading) {
        hideProgress();
      }

      logger.i('Handling Message after using mock data');
      if (onMessage != null) onMessage!(request, res);
      _handleLoginStep(request, res);
      if (onSuccess != null) onSuccess(res);
      return res;
    }

    String? fingerprint = ApexApiDb.getFingerprint();
    if (fingerprint == null) {
      logger.e('Could not create a valid fingerprint for the user : action (${request.action})');
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
              model: response!(result ?? {'success': -1}) as T,
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
    String requestMessage = await encrypt(crypto, request);

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

        responseMessage = decrypt(crypto, request, responseMessage);

        logger.i(
            'Response (${request.action}-${request.isPrivate ? 'PR' : 'PU'}-$T): $responseMessage');

        final decodedResponse = jsonDecode(responseMessage);
        res = BaseResponse<T>(
          data: decodedResponse,
          model: response!(decodedResponse) as T,
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
        if (showLoading) {
          hideProgress();
        }

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
      if (showLoading) {
        hideProgress();
      }
      if (res != null) {
        if (onMessage != null) {
          onMessage!(request, res);
        }
        _handleLoginStep(request, res);
      } else {
        if (onMessage != null) {
          onMessage!(request, BaseResponse<T>(error: exception, errorMessage: exception?.message));
        }
      }
    }

    return _handleRetry<T>(showRetry, retryClosure,
        BaseResponse<T>(error: exception, errorMessage: exception.message));
  }

  void _handleLoginStep(Request request, BaseResponse res) {
    if (res.success != null &&
        res.success! < 0 &&
        ![1001, 1002, 1003, 1004].contains(request.action)) {
      if (onLoginStepChanged != null) onLoginStepChanged!(res.loginStep);
    }
  }

  Future<BaseResponse<T>> _handleRetry<T extends DataModel>(bool show,
      Future<BaseResponse<T>> Function() retryClosure, BaseResponse<T> placeholder) async {
    Completer<BaseResponse<T>> completer = Completer<BaseResponse<T>>();
    if (show && onRetry != null) {
      onRetry!(() {
        completer.complete(retryClosure());
      });
    } else {
      completer.complete(placeholder);
    }
    return completer.future;
  }
}
