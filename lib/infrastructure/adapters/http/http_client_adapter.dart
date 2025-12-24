import 'package:http/http.dart' as http;

import 'package:sambura_core/application/ports/http_client_port.dart';

class HttpClientAdapter extends HttpClientPort {
  @override
  Future<HttpClientResponse> get(uri, {Map<String, String>? headers}) async {
    final response = await http.get(uri, headers: headers);
    return HttpClientResponse(
      statusCode: response.statusCode,
      body: response.body,
      bodyBytes: response.bodyBytes,
    );
  }

  @override
  Future<HttpClientResponse> post({
    required String uri,
    Map<String, String>? headers,
    data,
  }) {
    throw UnimplementedError();
  }

  @override
  Uri makeUri(
    String authority, [
    String? unencodedPath,
    Map<String, dynamic>? queryParameters,
  ]) {
    return Uri.https(authority, unencodedPath ?? '', queryParameters);
  }
}
