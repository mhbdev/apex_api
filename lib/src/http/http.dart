import 'dart:convert';

import 'package:apex_api/src/models/request.dart';

import 'package:apex_api/src/models/response.dart';
import 'package:flutter/foundation.dart';

import '../cipher/crypto.dart';
import '../connector.dart';

import 'package:http/http.dart' as http;

import '../exceptions.dart';

class Http extends Connector {
  late http.Client? client;

  Http(super.config, super.responseModels);

  @override
  void init() {
    if (!isInitialized) {
      client = http.Client(); //kIsWeb ? BrowserClient() : http.Client();
      isInitialized = true;
    }
  }

  @override
  Future<Res> send<Res extends ResponseModel>(Request request, {VoidCallback? onStart, bool? showProgress}) async {
    client ??= http.Client();

    String requestMessage = _encrypt(crypto, request);

    http.Response? response = request.method == Method.post
        ? await _post(request.handlerUrl ?? config.handlerUrl, config.namespace,
            requestMessage,
            timeLimit: config.requestTimeout, isPrivate: !request.isPublic)
        : await _get(
            request.handlerUrl ?? config.handlerUrl,
            config.namespace,
            requestMessage,
            timeLimit: config.requestTimeout,
          );

    if (response != null) {
      if (response.statusCode == 200) {
        // OK
        String responseMessage;
        if ((request.encrypt ?? false) || (encrypt)) {
          responseMessage = response.body.replaceAll(' ', '');
        } else {
          responseMessage = response.body;
        }

        responseMessage =
            _decrypt(crypto, responseMessage, enc: request.encrypt);

        try {
          var jsonResponse = jsonDecode(responseMessage);
          final response = responseModels[Res]!(jsonResponse) as Res;
          return response;
        } catch (e) {
          return Response(null, error: ConnectionError.parseResponseError) as Res;
        }
      } else {
        return Response(null,
            error: ConnectionError.statusNOK,
            errorMessage: '${response.statusCode}') as Res;
      }
    } else {
      return Response(null, error: ConnectionError.nullResponseError) as Res;
    }
  }

  String _encrypt(Crypto crypto, Request request) {
    String formattedRequest = jsonEncode(request.toJson());
    if (request.encrypt != null && request.encrypt == true) {
      formattedRequest = crypto.encrypt(formattedRequest);
      return formattedRequest;
    } else if (encrypt) {
      formattedRequest = crypto.encrypt(formattedRequest);
      return formattedRequest;
    }

    return formattedRequest;
  }

  String _decrypt(Crypto crypto, String responseMessage, {bool? enc}) {
    if (enc != null && enc == true) {
      responseMessage = crypto.decrypt(responseMessage);
      return responseMessage;
    } else if (encrypt) {
      responseMessage = crypto.decrypt(responseMessage);
      return responseMessage;
    }
    return responseMessage;
  }

  Future<http.Response?> _post(
      String url, String requestName, String requestMessage,
      {required timeLimit,
      onTimeOut,
      headers,
      encoding,
      bool isPrivate = true}) async {
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
  bool get isConnected => true;

}


// Future<Res> _makeHttpRequest() {
//   if (onStart != null) onStart!();
//   _showProgressDialog();
//
//   http.send(request).then((response) {
//     _hideProgressDialog();
//
//     if (response.hasError) {
//       if (onError != null) {
//         onError!(
//             response.error!,
//             ConnectionException(
//                 response.errorMessage ?? 'Something went wrong'),
//             connection: this);
//       }
//
//       completer.completeError('${response.error!} ${response.errorMessage}');
//     } else {
//       final res = responseModels[Res]!(response.data ?? {}) as Res;
//       onSuccess!(this, res);
//       if (!completer.isCompleted) {
//         completer.complete(res);
//       }
//     }
//
//     if (onComplete != null) onComplete!();
//   }).catchError((e) {
//     _hideProgressDialog();
//     if (onError != null) {
//       onError!(
//           ConnectionError.statusNOK,
//           ConnectionException(
//               e.toString() + e.runtimeType.toString()),
//           connection: this);
//     }
//   });
//   return completer.future;
// }
//
// Future<dynamic> progressDialog(
//     BuildContext context, {
//       Widget? progressWidget,
//       bool barrierDismissible = false,
//     }) {
//   final child = WillPopScope(
//     onWillPop: () => Future(() => barrierDismissible),
//     child: Align(
//       alignment: Alignment.center,
//       child: progressWidget ?? const CircularProgressIndicator(),
//     ),
//   );
//   return showDialog(
//     useRootNavigator: true,
//     context: context,
//     barrierDismissible: barrierDismissible,
//     builder: (context) => child,
//   );
// }
