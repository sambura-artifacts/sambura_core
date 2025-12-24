abstract class HttpClientPort {
  Future<dynamic> get(dynamic uri, {Map<String, String>? headers});
  Future<dynamic> post({
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
