import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:http/io_client.dart';

class FileRequest extends http.MultipartRequest {
  http.Client? client;
  final void Function(int bytes, int totalBytes)? onProgress;

  /// Creates a new [MultipartRequest].
  FileRequest(
    String method,
    Uri url, [
    this.onProgress,
    this.client,
  ]) : super(method, url) {
    client ??= kIsWeb ? BrowserClient() : IOClient(HttpClient());
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

    final total = contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}
