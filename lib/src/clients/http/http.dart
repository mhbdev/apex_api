import 'dart:convert';
import 'dart:io';

import 'package:apex_api/src/exceptions/bad_request_exception.dart';
import 'package:apex_api/src/models/request.dart';

import 'package:apex_api/src/models/response.dart';
import 'package:flutter/foundation.dart';
import 'browser_client.dart'
    if (dart.library.html) 'package:http/browser_client.dart';
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';

import '../../cipher/crypto.dart';
import '../../exceptions/server_error_exception.dart';
import '../../exceptions/server_exception.dart';
import '../../multipart_request.dart';
import '../connector.dart';

import 'package:http/http.dart' as http;

class Http extends Connector {
  http.Client? client;

  Http(super.config, super.responseModels);

  @override
  void init() {
    if (!isInitialized) {
      client = kIsWeb ? BrowserClient() : IOClient(HttpClient());
      isInitialized = true;
    }
  }

  @override
  Future<Res> send<Res extends Response>(
    Request request, {
    VoidCallback? onStart,
    bool? showProgress,
    bool? showRetry,
  }) async {
    client ??= kIsWeb ? BrowserClient() : IOClient(HttpClient());

    final crypto = Crypto(config.secretKey, config.publicKey);

    if (config.debugMode) {
      if (kDebugMode) {
        print(await request.toJson());
      }
    }

    String requestMessage = await _encrypt(crypto, request);

    if (onStart != null) onStart();
    if (showProgress == true) showProgressDialog();

    http.Response? response;
    try {
      response = request.method == Method.post
          ? await _post(request.handlerUrl ?? config.host, config.namespace,
              requestMessage,
              timeLimit: config.requestTimeout, isPrivate: !request.isPublic)
          : await _get(
              request.handlerUrl ?? config.host,
              config.namespace,
              requestMessage,
              timeLimit: config.requestTimeout,
            );
    } catch (e, s) {
      if (showProgress == true) hideProgressDialog();

      if (showRetry == true) {
        showRetryDialog(ServerErrorException(
          'Could not get the server response! something went wrong!',
        ));
      }
      return Response(null,
          error: ServerException(
              message: 'Could not parse server response! Here is the reason : \r\n$e',
              code: response != null ? response.statusCode.toString() : '-1'),
          errorMessage: '$e\r\n$s') as Res;
    }

    if (showProgress == true) hideProgressDialog();

    if (response != null) {
      if (response.statusCode == 200) {
        // OK
        String responseMessage;
        if ((request.encrypt ?? false) || (config.encrypt)) {
          responseMessage = response.body.replaceAll(' ', '');
        } else {
          responseMessage = response.body;
        }

        responseMessage =
            _decrypt(crypto, responseMessage, enc: request.encrypt);

        if (config.debugMode) {
          if (kDebugMode) {
            print(responseMessage);
          }
        }

        try {
          final res = responseModels[Res]!(jsonDecode(responseMessage)) as Res;
          handleMessage(res);
          return res;
        } on FormatException {
          if (showRetry == true) {
            showRetryDialog(ServerErrorException(
                'Could not parse server response! wanna retry?'));
          }
          return Response(null,
                  error:
                      ServerErrorException('Could not parse server response!'))
              as Res;
        }
      } else {
        if (showRetry == true) {
          showRetryDialog(ServerException(
              message: 'Could not parse server response!',
              code: response.statusCode.toString()));
        }
        return Response(null,
            error: ServerException(
                message: 'Could not parse server response!',
                code: response.statusCode.toString()),
            errorMessage: '${response.statusCode}') as Res;
      }
    } else {
      if (showRetry == true) {
        showRetryDialog(ServerErrorException(
          'Server response is null! This may be because of your internet connection or host being inaccessible',
        ));
      }
      return Response(null,
          error: ServerErrorException(
            'Server response is null! This may be because of your internet connection or host being inaccessible',
          )) as Res;
    }
  }

  Future<String> _encrypt(Crypto crypto, Request request) async {
    String formattedRequest = jsonEncode(await request.toJson());
    if (request.encrypt == false) {
      return formattedRequest;
    }

    if (config.encrypt || request.encrypt == true) {
      formattedRequest = crypto.encrypt(formattedRequest);
      return formattedRequest;
    }

    return formattedRequest;
  }

  String _decrypt(Crypto crypto, String responseMessage, {bool? enc}) {
    if (enc == false) {
      return responseMessage;
    }

    if (config.encrypt || enc == true) {
      responseMessage = crypto.decrypt(responseMessage);
      return responseMessage;
    }

    return responseMessage;
  }

  Future<http.Response?> _post(
    String url,
    String requestName,
    String requestMessage, {
    required timeLimit,
    onTimeOut,
    headers,
    encoding,
    bool isPrivate = true,
  }) async {
    var requestBody = {
      'os': os,
      'private': (isPrivate ? 1 : 0),
      'version': (isPrivate ? config.privateVersion : config.publicVersion),
      requestName: requestMessage
    };
    return client!
        .post(Uri.parse(url),
            headers: headers,
            body: {'request': jsonEncode(requestBody)},
            encoding: encoding ?? Encoding.getByName('utf-8'))
        .timeout(timeLimit, onTimeout: onTimeOut);
  }

  Future<http.Response?> _get(
      String url, String requestName, String requestMessage,
      {required timeLimit, onTimeOut, headers}) async {
    String queryUrl = '$url?$requestName=$requestMessage&os=$os';
    return client!
        .get(Uri.parse(queryUrl), headers: headers)
        .timeout(timeLimit, onTimeout: onTimeOut);
  }

  @override
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
  }) async {
    client ??= http.Client();

    Crypto crypto = Crypto(config.secretKey, config.publicKey);

    if (showProgress == true) showProgressDialog();

    if (request.handlerUrl == null && config.uploadHandlerUrl == null) {
      throw BadRequestException();
    }

    var req = FileRequest(request.method.name,
        Uri.parse(request.handlerUrl ?? config.uploadHandlerUrl ?? ''),
        (bytes, totalBytes) {
      if (onProgress != null) onProgress(bytes / totalBytes);
    });
    if (blobData != null) {
      req.files.add(http.MultipartFile.fromBytes(fileKey, blobData,
          contentType: MediaType('application', 'octet-stream'),
          filename: fileName));
    }

    if (filePath != null) {
      req.files.add(await http.MultipartFile.fromPath(fileKey, filePath));
    }

    String requestMessage = await _encrypt(crypto, request);

    req.fields['request'] = jsonEncode({
      'os': os,
      'version': request.isPublic ? config.publicVersion : config.privateVersion,
      'private': request.isPublic ? 0 : 1,
      config.namespace: requestMessage
    });
    if (cancelToken != null) cancelToken(req.close);

    try {
      var response = await req.send().timeout(config.uploadTimeout);

      if (showProgress == true) hideProgressDialog();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        responseBody = _decrypt(crypto, responseBody, enc: request.encrypt);

        try {
          var jsonResponse = jsonDecode(responseBody);
          final response = responseModels[Res]!(jsonResponse) as Res;
          return response;
        } on FormatException {
          if (showRetry == true) {
            showRetryDialog(ServerErrorException(
                'Could not parse server response! wanna retry?'));
          }
          return Response(null,
              error: ServerErrorException('Could not parse server response!'))
          as Res;
        }
      } else {
        if (showRetry == true) {
          showRetryDialog(ServerException(
              message: 'Could not parse server response!',
              code: response.statusCode.toString()));
        }
        return Response(null,
            error: ServerException(
                message: 'Could not parse server response!',
                code: response.statusCode.toString()),
            errorMessage: '${response.statusCode}') as Res;
      }
    } catch(e) {
      if (showProgress == true) hideProgressDialog();
      return Response(null,
          error: ServerException(
              message: 'Could not receive server response!',
              code: '-1'),
          errorMessage: '-1 ($e)') as Res;
    }
  }

  @override
  bool get isConnected => true;
}
