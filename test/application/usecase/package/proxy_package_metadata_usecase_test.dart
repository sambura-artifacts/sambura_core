import 'dart:convert';

import 'package:sambura_core/application/ports/http_client_port.dart';
import 'package:sambura_core/application/usecase/package/proxy_package_metadata_usecase.dart';
import 'package:test/test.dart';

class MockClient implements HttpClientPort {
  final Map<String, dynamic>? responseBody;
  final int statusCode;
  final List<int>? bodyBytes;
  final bool throwError;

  MockClient({
    this.responseBody,
    this.statusCode = 200,
    this.bodyBytes,
    this.throwError = false,
  });

  @override
  Future<HttpClientResponse> get(uri, {Map<String, String>? headers}) async {
    print(uri);

    if (throwError) {
      throw Exception('Network error');
    }

    if (uri.toString().contains('pacote-inexistente-xpto-123')) {
      return HttpClientResponse(statusCode: 404, bodyBytes: [00]);
    }

    if (uri.toString().contains('.tgz')) {
      return HttpClientResponse(
        statusCode: statusCode,
        bodyBytes: bodyBytes ?? [8, 2, 4, 5, 6],
      );
    }

    if (uri.toString().contains('search')) {
      final searchBody =
          responseBody ??
          {
            'objects': [
              {
                'package': {'name': 'lodash'},
              },
            ],
          };
      return HttpClientResponse(
        statusCode: statusCode,
        body: jsonEncode(searchBody),
        bodyBytes: [],
      );
    }

    final Map<String, dynamic> body =
        responseBody ??
        {
          'name': 'lodash',
          'versions': {
            '4.17.21': {
              'version': '4.17.21',
              'dist': {
                'tarball':
                    'https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz',
              },
            },
          },
        };

    return HttpClientResponse(
      statusCode: statusCode,
      body: jsonEncode(body),
      bodyBytes: bodyBytes ?? [8, 2, 4, 5, 6],
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

    test('deve reescrever tarball URLs com baseUrl do Samburá', () async {
      final result = await usecase.execute('lodash', repoName: 'npm-registry');

      expect(result, isNotNull);
      final versions = result!['versions'] as Map<String, dynamic>;
      final version = versions['4.17.21'] as Map<String, dynamic>;
      final dist = version['dist'] as Map<String, dynamic>;

      expect(dist['tarball'], contains('localhost:8080'));
      expect(dist['tarball'], contains('/api/v1/npm/npm-registry/lodash/-/'));
    });

    test('deve retornar bodyBytes quando path termina com .tgz', () async {
      final result = await usecase.execute(
        'lodash/-/lodash-4.17.21.tgz',
        repoName: 'npm-registry',
      );

      expect(result, isNotNull);
      expect(result, isA<List<int>>());
    });

    test(
      'deve retornar bodyBytes quando packageName termina com .tgz',
      () async {
        final result = await usecase.execute(
          '/lodash/-',
          packageName: 'lodash-4.17.21.tgz',
          repoName: 'npm-registry',
        );

        expect(result, isNotNull);
        expect(result, isA<List<int>>());
      },
    );

    test('deve processar search requests', () async {
      final mockWithSearch = MockClient(
        responseBody: {
          'objects': [
            {
              'package': {'name': 'express'},
            },
          ],
        },
      );
      final usecase = ProxyPackageMetadataUseCase(mockWithSearch);

      final result = await usecase.execute(
        '/-/v1/search?text=express',
        repoName: 'npm-registry',
      );

      expect(result, isNotNull);
      expect(result!['objects'], isA<List>());
    });

    test('deve retornar null quando ocorre erro de rede', () async {
      final mockWithError = MockClient(throwError: true);
      final usecase = ProxyPackageMetadataUseCase(mockWithError);

      final result = await usecase.execute('lodash', repoName: 'npm-registry');

      expect(result, isNull);
    });

    test('deve processar metadata sem versões', () async {
      final mockNoVersions = MockClient(
        responseBody: {'name': 'package-without-versions'},
      );
      final usecase = ProxyPackageMetadataUseCase(mockNoVersions);

      final result = await usecase.execute(
        'package-without-versions',
        repoName: 'npm-registry',
      );

      expect(result, isNotNull);
      expect(result!['name'], equals('package-without-versions'));
    });

    test('deve processar metadata com queryParams', () async {
      final result = await usecase.execute(
        'lodash',
        repoName: 'npm-registry',
        queryParams: {'version': '4.17.21'},
      );

      expect(result, isNotNull);
    });
  });
}
