class HttpClientResponse {
  final int statusCode;
  final List<int> bodyBytes;
  final dynamic body;

  HttpClientResponse({
    required this.statusCode,
    required this.bodyBytes,
    this.body,
  });
}

abstract class HttpClientPort {
  Future<HttpClientResponse> get(dynamic uri, {Map<String, String>? headers});
  Future<HttpClientResponse> post({
    required String uri,
    Map<String, String>? headers,
    dynamic data,
  });

  Uri makeUri(
    String authority, [
    String unencodedPath,
    Map<String, dynamic>? queryParameters,
  ]);
}
