import 'dart:typed_data';

class HttpClientResponse {
  final int statusCode;
  final Map<String, String> headers;
  final List<int> bodyBytes;
  final dynamic body;

  HttpClientResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
    required this.body,
  });
}

abstract class HttpClientPort {
  Future<HttpClientResponse> get(Uri uri, {Map<String, String>? headers});

  Future<HttpClientResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  });

  Future<HttpClientResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  });

  Future<HttpClientResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  });

  Future<({Stream<Uint8List> stream, int? length})> stream(
    Uri uri, {
    Map<String, String>? headers,
  });

  Uri makeUri(
    String host, {
    String? path,
    Map<String, dynamic>? queryParameters,
  });
}
