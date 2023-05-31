import 'dart:async';
import 'dart:io';

import 'package:apex_api/src/clients/http/browser_client.dart'
    if (dart.library.html) 'package:http/browser_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class FileRequest extends http.MultipartRequest {
  http.Client? client;
  final void Function(int bytes, int totalBytes)? onProgress;
  final Duration? connectionTimeout;

  /// Creates a new [MultipartRequest].
  FileRequest(
    String method,
    Uri url, [
    this.onProgress,
    this.connectionTimeout,
    this.client,
  ]) : super(method, url) {
    client ??=
        kIsWeb ? BrowserClient() : IOClient(HttpClient()..connectionTimeout = connectionTimeout);
  }

  void close() {
    client!.close();
  }

  @override
  Future<http.StreamedResponse> send() async {
    try {
      var response = await client!.send(this);
      var stream = onDone(response.stream, client!.close);
      return http.StreamedResponse(
        http.ByteStream(stream),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (_) {
      client!.close();
      rethrow;
    }
  }

  Stream<T> onDone<T>(Stream<T> stream, VoidCallback onDone) {
    return stream.transform(
      StreamTransformer.fromHandlers(
        handleDone: (sink) {
          sink.close();
          onDone();
        },
      ),
    );
  }

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    int bytes = 0;

    final stream = byteStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) async {
          sink.add(data);
          bytes += data.length;
          if (onProgress != null) {
            onProgress!(bytes, contentLength);
          }
        },
      ),
    );
    return http.ByteStream(stream);
  }
}
