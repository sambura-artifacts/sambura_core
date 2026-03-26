import 'dart:convert';

import 'package:sambura_core/infrastructure/api/presenter/error_presenter.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorPresenter', () {
    test('notFoundRoute returns Problem+JSON 404', () async {
      final response = ErrorPresenter.notFoundRoute(
        '/api/v1/unknown',
        'http://localhost:8080',
      );

      expect(response.statusCode, equals(404));
      expect(
        response.headers['Content-Type'],
        startsWith('application/problem+json'),
      );

      final body = jsonDecode(await response.readAsString());
      expect(body['type'], equals('about:blank'));
      expect(body['title'], equals('Not Found'));
      expect(body['status'], equals(404));
      expect(body['detail'], equals('Route not found'));
      expect(body['instance'], equals('/api/v1/unknown'));
    });

    test('serviceUnavailable returns Problem+JSON 503', () async {
      final response = ErrorPresenter.serviceUnavailable(
        'Serviço externo indisponível.',
        '/api/v1/npm/public/@babel/compat-data/-/compat-data-7.22.20.tgz',
        'http://localhost:8080',
      );

      expect(response.statusCode, equals(503));
      expect(
        response.headers['Content-Type'],
        startsWith('application/problem+json'),
      );

      final body = jsonDecode(await response.readAsString());
      expect(
        body['type'],
        equals('http://localhost:8080/docs/errors/service-unavailable'),
      );
      expect(body['title'], equals('Service Unavailable'));
      expect(body['status'], equals(503));
      expect(body['detail'], equals('Serviço externo indisponível.'));
      expect(
        body['instance'],
        equals(
          '/api/v1/npm/public/@babel/compat-data/-/compat-data-7.22.20.tgz',
        ),
      );
    });
  });
}
