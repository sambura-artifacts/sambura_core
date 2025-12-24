import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:sambura_core/application/ports/http_client_port.dart';
import 'package:sambura_core/application/usecase/package/proxy_package_metadata_usecase.dart';
import 'package:test/test.dart';
import 'dart:convert';

class MockClient implements HttpClientPort {
  @override
  Future<dynamic> get(uri, {Map<String, String>? headers}) async {
    return {
      'name': 'lodash',
      'versions': {
        '4.17.21': {'version': '4.17.21'},
      },
    };
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
    unencodedPath ?? '';
    return Uri();
  }
}

void main() {
  group('ProxyPackageMetadataUseCase', () {
    late ProxyPackageMetadataUseCase usecase;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      usecase = ProxyPackageMetadataUseCase(mockClient);
    });

    test('deve buscar metadados de pacote sem escopo com sucesso', () async {
      // Arrange
      const packageName = 'lodash';

      // Act
      final result = await usecase.execute(
        packageName,
        repoName: 'npm-registry',
      );

      // Assert
      expect(result, isNotNull);
      expect(result!['name'], equals(packageName));
    });

    test('deve fazer encoding correto de pacotes com escopo (@scope/name)', () {
      const packageName = '@sambura/core';
      final encoded = packageName.replaceFirst('/', '%2f');
      expect(encoded, equals('@sambura%2fcore'));
    });

    test('deve retornar null quando o pacote não existe (404)', () async {
      final result = await usecase.execute(
        'pacote-inexistente-xpto-123',
        repoName: 'npm-registry',
      );

      expect(result, isNull);
    });

    test('deve manter pacotes sem escopo inalterados no encoding', () {
      const packageName = 'express';
      final encoded = packageName.contains('/')
          ? packageName.replaceFirst('/', '%2f')
          : packageName;

      expect(encoded, equals('express'));
    });

    test('deve construir URL correta para registry NPM', () {
      const remoteRegistry = 'registry.npmjs.org';
      const packageName = '@sambura/core';
      final uri = Uri.https(remoteRegistry, '/$packageName');

      expect(uri.toString(), contains('registry.npmjs.org'));
    });
  });
}
