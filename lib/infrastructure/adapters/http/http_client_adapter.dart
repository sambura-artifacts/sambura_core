import 'package:http/http.dart' as http;

import 'package:sambura_core/application/ports/http_client_port.dart';

class HttpClientAdapter extends HttpClientPort {
  @override
  Future<dynamic> get(uri, {Map<String, String>? headers}) async {
    return await http.get(uri, headers: headers);
  }

  @override
  Future<dynamic> post({
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
