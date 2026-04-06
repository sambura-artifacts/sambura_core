import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:sambura_core/config/logger.dart';

import 'package:sambura_core/application/barrel.dart';

class HttpClientAdapter extends HttpClientPort {
  final http.Client _client;
  final Logger _log = LoggerConfig.getLogger('HttpClientAdapter');

  HttpClientAdapter(this._client);

  @override
  Future<HttpClientResponse> get(uri, {Map<String, String>? headers}) async {
    final response = await http.get(uri, headers: headers);
    return HttpClientResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
      bodyBytes: response.bodyBytes,
    );
  }

  @override
  Future<HttpClientResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final response = await http.post(uri, headers: headers, body: body);
    return HttpClientResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
      bodyBytes: response.bodyBytes,
    );
  }

  @override
  Future<HttpClientResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final response = await http.put(uri, headers: headers, body: body);
    return HttpClientResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
      bodyBytes: response.bodyBytes,
    );
  }

  @override
  Future<HttpClientResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final response = await http.delete(uri, headers: headers, body: body);
    return HttpClientResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
      bodyBytes: response.bodyBytes,
    );
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
      _log.fine('🌐 [HTTP] GET ${uri.host}${uri.path}');
      final request = http.Request('GET', uri);
      if (headers != null) request.headers.addAll(headers);

      final http.StreamedResponse response = await _client
          .send(request)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              _log.warning('⏱️ [HTTP] Timeout 60s para ${uri.host}${uri.path}');
              throw ExternalServiceUnavailableException(
                'Timeout ao conectar em ${uri.host}',
                details: {'uri': uri.toString()},
              );
            },
          );

      if (response.statusCode != 200) {
        _log.warning(
          '⚠️ [HTTP] Status ${response.statusCode} ${_getStatusMessage(response.statusCode)} para ${uri.host}${uri.path}',
        );
        throw ExternalServiceUnavailableException(
          'HTTP ${response.statusCode}: ${_getStatusMessage(response.statusCode)} para ${uri.path}',
          details: {
            'status': response.statusCode,
            'uri': uri.toString(),
            'host': uri.host,
          },
        );
      }

      _log.info(
        '✅ [HTTP] 200 OK ${uri.host}${uri.path} (${response.contentLength} bytes)',
      );
      return (
        stream: response.stream.cast<Uint8List>(),
        length: response.contentLength,
      );
    } on ExternalServiceUnavailableException catch (e) {
      _log.severe('🚨 [HTTP] Erro na requisição a ${uri.host}: ${e.message}');
      rethrow;
    } catch (e, st) {
      _log.severe(
        '❌ [HTTP] Erro inesperado ao conectar em ${uri.host}${uri.path}',
        e,
        st,
      );
      throw ExternalServiceUnavailableException(
        'Erro ao baixar de ${uri.host}: ${e.toString()}',
        details: {'uri': uri.toString(), 'error': e.toString()},
      );
    }
  }

  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 404:
        return 'Not Found';
      case 403:
        return 'Forbidden';
      case 500:
        return 'Internal Server Error';
      case 503:
        return 'Service Unavailable';
      default:
        return 'HTTP Error';
    }
  }
}
