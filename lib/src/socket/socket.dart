import 'dart:async';
import 'dart:convert';

import 'package:apex_api/src/models/request.dart';
import 'package:apex_api/src/models/response.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../connector.dart';
import '../exceptions.dart';
import '../typedefs.dart';

class ApexSocket extends Connector {
  late io.Socket socket;

  /// Check if socket object is created and connected as well :)
  @override
  bool get isConnected => socket.connected;

  final int? port;
  final String url;

  /// Just works on encrypt = true
  final String? namespace;
  final io.OptionBuilder options;
  final EventHandler? onConnect,
      onConnectError,
      onError,
      onDisconnect,
      onReconnect;

  int delay = 1;
  int elapsed = 2;
  Timer? timer;
  ConnectionStatus status = ConnectionStatus.connecting;

  ApexSocket(
    super.config,
    super.responseModels, {
    this.onConnect,
    this.onConnectError,
    this.onError,
    this.onDisconnect,
    this.onReconnect,
  })  : options = config.options,
        namespace = config.namespace,
        port = config.port,
        url = config.handlerUrl,
        assert(Uri.parse(config.handlerUrl).isAbsolute,
            '${config.handlerUrl} must be a valid url.'),
        assert(
            config.port == null ||
                (config.port! >= -1 && config.port! <= 65535),
            '${config.port} must be a number between -1 and 65535. or null.');

  io.Socket connect({EventHandler? onConnect}) {
    if (onConnect != null) socket.onConnect(onConnect);

    if (!socket.connected) {
      return socket.connect();
    }
    return socket;
  }

  Future<io.Socket> connectAsync() async {
    Completer<io.Socket> ioSocket = Completer<io.Socket>();

    socket.onConnect(
      (data) {
        if (!ioSocket.isCompleted) {
          ioSocket.complete(socket);
        }
      },
    );

    if (!socket.connected) {
      return socket.connect();
    }

    return ioSocket.future;
  }

  @override
  void init() {
    if (!isInitialized) {
      socket = io.io(
          '$url${port != null ? ':$port' : ''}${namespace != null ? '/$namespace' : ''}',
          options.setTransports(['websocket']).build());

      connect();

      socket.onConnect((data) {
        status = ConnectionStatus.connected;
        _notifyStatus();
        if (onConnect != null) return onConnect!(data);
      });

      socket.onConnectError((data) {
        _reconnect();
        status = ConnectionStatus.error;
        _notifyStatus();
        if (onConnectError != null) onConnectError!(data);
      });

      socket.onError((data) {
        _reconnect();
        status = ConnectionStatus.error;
        _notifyStatus();
        if (onError != null) onError!(data);
      });

      socket.onDisconnect((data) {
        _reconnect();
        status = ConnectionStatus.destroyed;
        _notifyStatus();
        if (onDisconnect != null) return onDisconnect!(data);
      });

      socket.onReconnect((data) {
        status = ConnectionStatus.connecting;
        _notifyStatus();
        if (onReconnect != null) onReconnect!(data);
      });

      socket.onReconnecting((data) {
        status = ConnectionStatus.connecting;
        _notifyStatus();
      });

      isInitialized = true;
    }
  }

  void privateEmit({String data = '', bool? enc}) {
    bool shouldEncrypt = enc ?? encrypt;

    if (shouldEncrypt) {
      data = crypto.encrypt(data);
    } else {
      data = base64Encode(utf8.encode(data));
    }

    socket.emit(
        config.eventName,
        jsonEncode({
          'os': os,
          'private': 1,
          'version': config.privateVersion,
          'data': data,
        }));
  }

  void publicEmit({String data = '', bool? enc}) {
    data = base64Encode(utf8.encode(data));
    socket.emit(
        config.eventName,
        jsonEncode({
          'os': os,
          'private': 0,
          'version': config.publicVersion,
          'data': data,
        }));
  }

  void privateEmitWithAck(Json request, void Function(String? data) ack,
      {bool? enc}) {
    final shouldEncrypt = ((enc == null) ? encrypt : enc);
    String data = jsonEncode(request);

    if (shouldEncrypt) {
      data = crypto.encrypt(data);
    } else {
      data = base64Encode(utf8.encode(data));
    }
    socket.emitWithAck(
        config.eventName,
        jsonEncode({
          'os': os,
          'private': 1,
          'version': config.privateVersion,
          'data': data,
        }), ack: (m) {
      if (shouldEncrypt) {
        try {
          final decryptedMessage = crypto.decrypt(m.toString());
          ack(decryptedMessage);
        } catch (ignore) {
          ack(null);
        }
      } else {
        ack(m.toString());
      }
    });
  }

  void publicEmitWithAck(Json request, void Function(String? data) ack,
      {bool? enc}) {
    final shouldEncrypt = enc ?? encrypt;
    String data = jsonEncode(request);

    if (shouldEncrypt) {
      data = crypto.encrypt(data);
    } else {
      data = base64Encode(utf8.encode(data));
    }
    socket.emitWithAck(
        config.eventName,
        jsonEncode({
          'os': os,
          'private': 0,
          'version': config.publicVersion,
          'data': data,
        }), ack: (m) {
      if (shouldEncrypt) {
        try {
          final decryptedMessage = crypto.decrypt(m.toString());
          ack(decryptedMessage);
        } catch (ignore) {
          ack(null);
        }
      } else {
        ack(m.toString());
      }
    });
  }

  Future privateEmitWithCompleter(String data, {bool? enc}) {
    final shouldEncrypt = enc ?? encrypt;

    Completer completer = Completer();

    if (shouldEncrypt) {
      data = crypto.encrypt(data);
    } else {
      data = base64Encode(utf8.encode(data));
    }
    socket.emitWithAck(
        config.eventName,
        jsonEncode({
          'os': os,
          'private': 1,
          'version': config.privateVersion,
          'data': data,
        }), ack: (m) {
      if (shouldEncrypt) {
        try {
          final decryptedMessage = crypto.decrypt(m.toString());
          if (!completer.isCompleted) completer.complete(decryptedMessage);
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(NullResponseError(e.toString()));
          }
        }
      } else {
        if (!completer.isCompleted) completer.complete(m.toString());
      }
    });

    socket.on('connect_error', (data) {
      if (!completer.isCompleted) {
        completer.completeError(ConnectionException(data.toString()));
      }
    });

    return completer.future;
  }

  Future publicEmitWithCompleter(String data) {
    final completer = Completer();

    data = base64Encode(utf8.encode(data));

    socket.emitWithAck(
        config.eventName,
        jsonEncode({
          'os': os,
          'private': 0,
          'version': config.publicVersion,
          'data': data,
        }), ack: (m) {
      if (!completer.isCompleted) completer.complete(m.toString());
    });

    socket.on('connect_error', (data) {
      if (!completer.isCompleted) {
        completer.completeError(ConnectionException(data.toString()));
      }
    });

    return completer.future;
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
      notifyListeners('status', status);
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

  @override
  Future<Res> send<Res extends ResponseModel>(Request request,
      {VoidCallback? onStart, bool? showProgress}) {
    Completer<Res> completer = Completer();
    if (status == ConnectionStatus.connected) {
      if (onStart != null) onStart();
      if (showProgress == true) {
        showProgressDialog();
      }

      if (request.isPublic) {
        _publicEmit<Res>(completer, request);
      } else {
        _privateEmit<Res>(completer, request);
      }
    } else {
      connect(onConnect: (data) {
        if (retried < maxRetry) {
          retried++;
          send(request);
        } else {
          retried = 1;
        }
      });
    }
    return completer.future;
  }

  void _publicEmit<Res extends ResponseModel>(Completer completer, Request request) async {
    publicEmitWithAck(await request.toJson(), (data) {
      _handleResponse<Res>(completer, request, data);
    }, enc: false);
  }

  void _privateEmit<Res extends ResponseModel>(Completer completer, Request request) async {
    privateEmitWithAck(await request.toJson(), (data) {
      _handleResponse<Res>(completer, request, data);
    }, enc: request.encrypt);
  }

  void _handleResponse<Res extends ResponseModel>(
      Completer completer, Request request, String? data) {
    hideProgressDialog();

    if (config.debugMode) {
      debugPrint(
          'ACTION: ${request.action}, PUBLIC: ${request.isPublic}, GROUP_NAME: ${request.groupName}, $data');
    }

    if (data == null || data == 'null') {
      if (onError != null) {
        // onError!(ConnectionError.nullResponseError,
        //     ConnectionException('Server response is null!'),
        //     connection: this);
      }

      completer.completeError(ConnectionError.nullResponseError);
      showRetryDialog(RetryReason.responseIsNull);
      return;
    }

    try {
      final parsed = jsonDecode(data);

      if (parsed != null) {
        final res = responseModels[Res]!(parsed) as Res;
        if (!completer.isCompleted) {
          completer.complete(res);
        }
      } else {
        // if (onError != null) {
        //   onError!(ConnectionError.nullResponseError,
        //       ConnectionException('Server response is null!'),
        //       connection: this);
        // }
        completer.completeError(ConnectionError.nullResponseError);
        showRetryDialog(RetryReason.responseIsNull);
      }
    } on FormatException {
      // if (onError != null) {
      //   onError!(ConnectionError.parseResponseError, ConnectionException(data),
      //       connection: this);
      // }
      completer.completeError(ConnectionError.parseResponseError);
      showRetryDialog(RetryReason.jsonFormatException);
    }
    // finally {
    //   if (onComplete != null) onComplete!();
    // }
  }

  void _notifyStatus() {
    notifyListeners('status', status);
  }
}

enum ConnectionStatus { reconnecting, connecting, connected, error, destroyed }
