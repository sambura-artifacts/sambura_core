import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:sambura_core/application/barrel.dart';

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
      return HttpClientResponse(
        statusCode: 404,
        headers: {'content-type': 'application/stream'},
        bodyBytes: [00],
        body: null,
      );
    }

    if (uri.toString().contains('.tgz')) {
      return HttpClientResponse(
        statusCode: statusCode,
        headers: {'content-type': 'application/stream'},
        bodyBytes: bodyBytes ?? [8, 2, 4, 5, 6],
        body: null,
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
        headers: {'content-type': 'application/json'},
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
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
      bodyBytes: bodyBytes ?? [8, 2, 4, 5, 6],
    );
  }

  @override
  Future<HttpClientResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    if (throwError) {
      throw Exception('Network error');
    }
    return HttpClientResponse(
      statusCode: statusCode,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(responseBody ?? {}),
      bodyBytes: bodyBytes ?? [],
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
  Future<({int? length, Stream<Uint8List> stream})> stream(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    if (throwError) {
      throw Exception('Network error');
    }
    final stream = Stream.fromIterable([Uint8List.fromList(bodyBytes ?? [])]);
    return (length: bodyBytes?.length, stream: stream);
  }

  @override
  Future<HttpClientResponse> delete(
    Uri uri, {
    Map<String, String>? headers,
    body,
  }) async {
    if (throwError) {
      throw Exception('Network error');
    }
    return HttpClientResponse(
      statusCode: statusCode,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(responseBody ?? {}),
      bodyBytes: bodyBytes ?? [],
    );
  }

  @override
  Future<HttpClientResponse> put(
    Uri uri, {
    Map<String, String>? headers,
    body,
  }) async {
    if (throwError) {
      throw Exception('Network error');
    }
    return HttpClientResponse(
      statusCode: statusCode,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(responseBody ?? {}),
      bodyBytes: bodyBytes ?? [],
    );
  }
}

void main() {
  group('NpmProxyPackageMetadataUseCase', () {
    late NpmProxyPackageMetadataUseCase usecase;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      usecase = NpmProxyPackageMetadataUseCase(mockClient);
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
      final usecase = NpmProxyPackageMetadataUseCase(mockWithSearch);

      final result = await usecase.execute(
        '/-/v1/search?text=express',
        repoName: 'npm-registry',
      );

      expect(result, isNotNull);
      expect(result!['objects'], isA<List>());
    });

    test('deve retornar null quando ocorre erro de rede', () async {
      final mockWithError = MockClient(throwError: true);
      final usecase = NpmProxyPackageMetadataUseCase(mockWithError);

      final result = await usecase.execute('lodash', repoName: 'npm-registry');

      expect(result, isNull);
    });

    test('deve processar metadata sem versões', () async {
      final mockNoVersions = MockClient(
        responseBody: {'name': 'package-without-versions'},
      );
      final usecase = NpmProxyPackageMetadataUseCase(mockNoVersions);

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
