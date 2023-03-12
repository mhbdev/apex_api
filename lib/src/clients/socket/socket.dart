// import 'dart:async';
// import 'dart:convert';
//
// import 'package:apex_api/src/models/request.dart';
// import 'package:apex_api/src/models/response.dart';
// import 'package:flutter/foundation.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io;
//
// import '../../cipher/crypto.dart';
// import '../../exceptions/server_error_exception.dart';
// import '../../typedefs.dart';
// import '../connector.dart';
//
// class ApexSocket extends Connector {
//   late io.Socket socket;
//
//   /// Check if socket object is created and connected as well :)
//   @override
//   bool get isConnected => socket.connected;
//
//   final int? port;
//   final String url;
//
//   /// Just works on encrypt = true
//   final String? namespace;
//   final io.OptionBuilder options;
//
//   int delay = 1;
//   int elapsed = 2;
//   Timer? timer;
//   ConnectionStatus status = ConnectionStatus.connecting;
//
//   ApexSocket(
//     super.config,
//     super.responseModels,
//   )   : options = config.options ??
//             io.OptionBuilder().disableAutoConnect().disableForceNew().disableForceNewConnection(),
//         namespace = config.namespace,
//         port = config.port,
//         url = config.host,
//         assert(Uri.parse(config.host).isAbsolute, '${config.host} must be a valid url.'),
//         assert(config.port == null || (config.port! >= -1 && config.port! <= 65535),
//             '${config.port} must be a number between -1 and 65535. or null.');
//
//   io.Socket connect({EventHandler? onConnect}) {
//     socket.onConnect((data) {
//       if (status != ConnectionStatus.connected) {
//         // print('onConnect (${socket.id}) $data');
//         status = ConnectionStatus.connected;
//         _notifyStatus();
//       }
//
//       if (onConnect != null) {
//         onConnect(data);
//       }
//     });
//
//     if (!socket.connected) {
//       socket.connect();
//     }
//     return socket;
//   }
//
//   Future<io.Socket> connectAsync() async {
//     Completer<io.Socket> ioSocket = Completer<io.Socket>();
//
//     socket.onConnect(
//       (data) {
//         if (!ioSocket.isCompleted) {
//           ioSocket.complete(socket);
//         }
//       },
//     );
//
//     if (!socket.connected) {
//       socket.connect();
//     }
//
//     return ioSocket.future;
//   }
//
//   @override
//   void init() {
//     if (!isInitialized) {
//       socket = io.io(
//         '$url${port != null ? ':$port' : ''}${namespace != null ? '/$namespace' : ''}',
//         options.setTransports(['websocket']).build(),
//       );
//
//       connect();
//
//       socket.onConnect((data) {
//         // print('onConnect (${socket.id}) $data');
//         status = ConnectionStatus.connected;
//         _notifyStatus();
//       });
//
//       socket.onConnectError((data) {
//         // print('onConnectError (${socket.id}) $data');
//         _reconnect();
//         status = ConnectionStatus.error;
//         _notifyStatus();
//       });
//
//       socket.onError((data) {
//         // print('onError (${socket.id}) $data');
//         _reconnect();
//         status = ConnectionStatus.error;
//         _notifyStatus();
//       });
//
//       socket.onDisconnect((data) {
//         // print('onDisconnect (${socket.id}) $data');
//         _reconnect();
//         status = ConnectionStatus.destroyed;
//         _notifyStatus();
//       });
//
//       socket.onReconnect((data) {
//         // print('onReconnect (${socket.id}) $data');
//         status = ConnectionStatus.connecting;
//         _notifyStatus();
//       });
//
//       socket.onReconnecting((data) {
//         // print('onReconnecting (${socket.id}) $data');
//         status = ConnectionStatus.connecting;
//         _notifyStatus();
//       });
//
//       socket.onConnectTimeout((data) {
//         // print('onConnectTimeout (${socket.id}) $data');
//         status = ConnectionStatus.timeout;
//         _notifyStatus();
//       });
//
//       isInitialized = true;
//     }
//   }
//
//   // void privateEmit({String data = '', bool? enc}) {
//   //   bool shouldEncrypt = enc ?? config.encrypt;
//   //
//   //   if (shouldEncrypt) {
//   //     data = crypto.encrypt(data);
//   //   } else {
//   //     data = base64Encode(utf8.encode(data));
//   //   }
//   //
//   //   socket.emit(
//   //       config.eventName,
//   //       jsonEncode({
//   //         'os': os,
//   //         'private': 1,
//   //         'version': config.privateVersion,
//   //         'data': data,
//   //       }));
//   // }
//
//   void publicEmit({String data = '', bool? enc}) {
//     data = base64Encode(utf8.encode(data));
//     socket.emit(
//         config.eventName,
//         jsonEncode({
//           'os': os,
//           'private': 0,
//           'version': config.publicVersion,
//           'data': data,
//         }));
//   }
//
//   void privateEmitWithAck(Crypto crypto, Json request, void Function(String? data) ack,
//       {bool? enc}) {
//     final shouldEncrypt = ((enc == null) ? config.encrypt : enc);
//     String data = jsonEncode(request);
//
//     if (shouldEncrypt) {
//       data = crypto.encrypt(data);
//     } else {
//       data = base64Encode(utf8.encode(data));
//     }
//     socket.emitWithAck(
//         config.eventName,
//         jsonEncode({
//           'os': os,
//           'private': 1,
//           'version': config.privateVersion,
//           'data': data,
//         }), ack: (m) {
//       if (shouldEncrypt) {
//         try {
//           final decryptedMessage = crypto.decrypt(m.toString());
//           ack(decryptedMessage);
//         } catch (ignore) {
//           ack(null);
//         }
//       } else {
//         ack(m.toString());
//       }
//     });
//   }
//
//   void publicEmitWithAck(Crypto crypto, Json request, void Function(String? data) ack,
//       {bool? enc}) {
//     final shouldEncrypt = enc ?? config.encrypt;
//     String data = jsonEncode(request);
//
//     if (shouldEncrypt) {
//       data = crypto.encrypt(data);
//     } else {
//       data = base64Encode(utf8.encode(data));
//     }
//     socket.emitWithAck(
//         config.eventName,
//         jsonEncode({
//           'os': os,
//           'private': 0,
//           'version': config.publicVersion,
//           'data': data,
//         }), ack: (m) {
//       if (shouldEncrypt) {
//         try {
//           final decryptedMessage = crypto.decrypt(m.toString());
//           ack(decryptedMessage);
//         } catch (ignore) {
//           ack(null);
//         }
//       } else {
//         ack(m.toString());
//       }
//     });
//   }
//
//   void _reconnect() {
//     if (delay < 64) {
//       delay *= 2;
//     } else {
//       delay = 1;
//     }
//     elapsed = delay;
//     timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (elapsed > 0) {
//         elapsed--;
//       } else {
//         timer.cancel();
//         connect();
//         status = ConnectionStatus.reconnecting;
//       }
//       notifyListeners('status', status);
//     });
//   }
//
//   void connectReset() {
//     delay = 1;
//     if (timer != null) {
//       timer!.cancel();
//     }
//     connect();
//     status = ConnectionStatus.reconnecting;
//     _notifyStatus();
//   }
//
//   @override
//   Future<BaseResponse<DM>> send<DM extends DataModel>(
//     Request request, {
//     bool? showProgress,
//     bool? showRetry,
//   }) async {
//     final crypto = Crypto(config.secretKey, config.publicKey);
//
//     if (config.debugMode) {
//       if (kDebugMode) {
//         print('[ZIP-REQUEST] [$DM] [${DateTime.now()}] [${await request.zip}]');
//       }
//     }
//
//     Future<BaseResponse<DM>> response;
//     if (status == ConnectionStatus.connected) {
//       response = _emit<DM>(crypto, request, showProgress: showProgress, showRetry: showRetry);
//     } else {
//       await connectAsync();
//       response = _emit<DM>(crypto, request, showProgress: showProgress, showRetry: showRetry);
//     }
//
//     if (config.debugMode) {
//       if (kDebugMode) {
//         // TODO : uncomment
//         // print('[ZIP-RESPONSE] [$Res] [${DateTime.now()}] [${(await response).data}]');
//       }
//     }
//
//     return response;
//   }
//
//   Future<BaseResponse<DM>> _emit<DM extends DataModel>(Crypto crypto, Request request,
//       {bool? showProgress, bool? showRetry}) async {
//     Completer<BaseResponse<DM>> completer = Completer<BaseResponse<DM>>();
//
//     if (showProgress == true) {
//       showProgressDialog();
//     }
//
//     if (request.isPublic) {
//       publicEmitWithAck(crypto, await request.toJson(), (data) {
//         if (showProgress == true) {
//           hideProgressDialog();
//         }
//         try {
//           _handleResponse<DM>(completer, request, data, showRetry: showRetry);
//         } catch (e, s) {
//           completer.completeError(e, s);
//         }
//       }, enc: false);
//     } else {
//       privateEmitWithAck(crypto, await request.toJson(), (data) {
//         if (showProgress == true) {
//           hideProgressDialog();
//         }
//         try {
//           _handleResponse<DM>(completer, request, data, showRetry: showRetry);
//         } catch (e, s) {
//           completer.completeError(e, s);
//         }
//       }, enc: request.encrypt);
//     }
//
//     return completer.future;
//   }
//
//   void _handleResponse<DM extends DataModel>(
//       Completer<BaseResponse<DM>> completer, Request request, String? data,
//       {bool? showRetry}) {
//     if (data == null || data == 'null') {
//       completer.completeError(ServerErrorException(
//         'Server response is null! This may be because of your internet connection or host being inaccessible',
//       ));
//       if (showRetry == true) {
//         showRetryDialog(ServerErrorException(
//           'Server response is null! This may be because of your internet connection or host being inaccessible',
//         ));
//       }
//       return;
//     }
//
//     try {
//       final parsed = jsonDecode(data);
//       if (parsed != null) {
//         final res = BaseResponse(
//             data: parsed,
//             model: responseModels[DM]!(config.useMocks ? request.responseMock : parsed) as DM);
//
//         if (!completer.isCompleted) {
//           completer.complete(res);
//         }
//       } else {
//         _couldNotParseException(completer, showRetry);
//       }
//     } on FormatException {
//       _couldNotParseException(completer, showRetry);
//     }
//   }
