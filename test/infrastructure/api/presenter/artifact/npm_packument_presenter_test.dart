import 'package:sambura_core/infrastructure/api/presenter/artifact/npm_packument_presenter.dart';
import 'package:test/test.dart';
import 'dart:convert';

void main() {
  group('NpmPackumentPresenter.success', () {
    test('deve retornar Response com status 200', () {
      final metadata = {'name': 'test', 'versions': {}, 'dist-tags': {}};
      final response = NpmPackumentPresenter.success(metadata);

      expect(response.statusCode, equals(200));
    });

    test('deve incluir headers corretos', () {
      final metadata = {'name': 'test'};
      final response = NpmPackumentPresenter.success(metadata);

      expect(response.headers['Content-Type'], equals('application/json'));
      expect(response.headers['X-Powered-By'], equals('Sambura Registry'));
    });

    test('deve serializar metadata como JSON', () async {
      final metadata = {
        'name': 'lodash',
        'versions': {'4.17.21': {}},
        'dist-tags': {'latest': '4.17.21'},
      };

      final response = NpmPackumentPresenter.success(metadata);
      final body = await response.readAsString();
      final decoded = jsonDecode(body);

      expect(decoded['name'], equals('lodash'));
      expect(decoded['versions'], isNotEmpty);
    });

    test('deve preservar pacotes com escopo', () async {
      final metadata = {
        'name': '@sambura/core',
        'versions': {'1.0.0': {}},
        'dist-tags': {'latest': '1.0.0'},
      };

      final response = NpmPackumentPresenter.success(metadata);
      final body = await response.readAsString();
      final decoded = jsonDecode(body);

      expect(decoded['name'], equals('@sambura/core'));
      expect(decoded['name'], startsWith('@'));
    });
  });

  group('NpmPackumentPresenter.error', () {
    test('deve retornar Response com status code correto', () {
      final response = NpmPackumentPresenter.error(404, 'Not found');
      expect(response.statusCode, equals(404));
    });

    test('deve incluir headers corretos em erros', () {
      final response = NpmPackumentPresenter.error(404, 'Not found');

      expect(response.headers['Content-Type'], equals('application/json'));
      expect(response.headers['X-Powered-By'], equals('Sambura Registry'));
    });

    test('deve mapear 404 para "not_found"', () async {
      final response = NpmPackumentPresenter.error(404, 'Package not found');
      final body = await response.readAsString();
      final decoded = jsonDecode(body);

      expect(decoded['error'], equals('not_found'));
      expect(decoded['reason'], equals('Package not found'));
    });

    test('deve mapear 403 para "forbidden"', () async {
      final response = NpmPackumentPresenter.error(403, 'Access denied');
      final body = await response.readAsString();
      final decoded = jsonDecode(body);

      expect(decoded['error'], equals('forbidden'));
      expect(decoded['reason'], equals('Access denied'));
    });

    test('deve mapear outros erros para "internal_server_error"', () async {
      final testCases = [400, 500, 502];

      for (final code in testCases) {
        final response = NpmPackumentPresenter.error(code, 'Error');
        final body = await response.readAsString();
        final decoded = jsonDecode(body);

        expect(decoded['error'], equals('internal_server_error'));
      }
    });
  });
}
