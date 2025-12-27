import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:sambura_core/application/exceptions/exceptions.dart';
import 'package:sambura_core/application/ports/ports.dart';



class HttpClientAdapter extends HttpClientPort {
  final http.Client _client;

  HttpClientAdapter(this._client);

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
    String authority, {
    String? path,
    Map<String, dynamic>? queryParameters,
  }) {
    return Uri.https(authority, path ?? '', queryParameters);
  }

  @override
  Future<({Stream<Uint8List> stream, int? length})> stream(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.Request('GET', uri);
      if (headers != null) request.headers.addAll(headers);

      final http.StreamedResponse response = await _client.send(request);

      if (response.statusCode != 200) {
        // Aqui você saberá se é um 404, 403, etc.
        throw ExternalServiceUnavailableException(
          'NPM respondeu com erro: ${response.statusCode}',
          details: {'status': response.statusCode, 'uri': uri.toString()},
        );
      }

      return (
        stream: response.stream.cast<Uint8List>(),
        length: response.contentLength,
      );
    } catch (e) {
      if (e is ExternalServiceUnavailableException) rethrow;
      throw ExternalServiceUnavailableException('Erro de conexão física: $e');
    }
  }
}
