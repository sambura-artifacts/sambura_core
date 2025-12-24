import 'dart:convert';
import 'package:shelf/shelf.dart';

class NpmPackumentPresenter {
  static const _headers = {
    'Content-Type': 'application/json',
    'X-Powered-By': 'Sambura Registry',
  };

  static Response success(Map<String, dynamic> metadata) {
    return Response.ok(jsonEncode(metadata), headers: _headers);
  }

  static Response error(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': _getNpmError(statusCode), 'reason': message}),
      headers: _headers,
    );
  }

  static String _getNpmError(int code) {
    if (code == 404) return 'not_found';
    if (code == 403) return 'forbidden';
    return 'internal_server_error';
  }
}
