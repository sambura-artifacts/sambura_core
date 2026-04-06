import 'dart:async';
import 'dart:typed_data';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class MockHttpClient extends Mock implements HttpClientPort {}

class MockCreateArtifactUsecase extends Mock implements CreateArtifactUsecase {}

class MockGetArtifactDownloadStreamUsecase extends Mock
    implements GetArtifactDownloadStreamUsecase {}

class MockNamespaceRepository extends Mock implements NamespaceRepository {}

class MockCache extends Mock implements CachePort {}

class MockMetrics extends Mock implements MetricsPort {}

class MockArtifactDownloadResult extends Mock
    implements ArtifactDownloadResult {}

void main() {
  late NpmHandler npmHandler;
  late MockHttpClient mockHttpClient;
  late MockCreateArtifactUsecase mockCreateArtifactUsecase;
  late MockGetArtifactDownloadStreamUsecase
  mockGetArtifactDownloadStreamUsecase;
  late MockNamespaceRepository mockNamespaceRepository;
  late MockCache mockCache;
  late MockMetrics mockMetrics;

  setUpAll(() {
    // 1. REGISTROS DE FALLBACK OBRIGATÓRIOS PARA O ANY() DO MOCKTAIL
    registerFallbackValue(
      InfraestructureArtifactInput(
        packageManager: 'npm',
        namespace: '',
        packageName: '',
        version: '',
      ),
    );
    registerFallbackValue(Stream<List<int>>.empty());
    registerFallbackValue(
      Uri.parse('https://registry.npmjs.org'),
    ); // Necessário pro HttpClient
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockCreateArtifactUsecase = MockCreateArtifactUsecase();
    mockGetArtifactDownloadStreamUsecase =
        MockGetArtifactDownloadStreamUsecase();
    mockNamespaceRepository = MockNamespaceRepository();
    mockCache = MockCache();
    mockMetrics = MockMetrics();

    // 2. STUBS GLOBAIS PARA VOID METHODS (Evita NoMatchingStubError)
    when(() => mockMetrics.incrementCounter(any())).thenAnswer((_) {});
    when(
      () => mockMetrics.observeHistogram(
        any(),
        any(),
        labels: any(named: 'labels'),
      ),
    ).thenAnswer((_) {});

    npmHandler = NpmHandler(
      mockHttpClient,
      mockCreateArtifactUsecase,
      mockGetArtifactDownloadStreamUsecase,
      mockNamespaceRepository,
      mockCache,
      mockMetrics,
    );
  });

  group('npmHandler', () {
    // -------------------------------------------------------------------------
    // TESTES DE ROTEAMENTO (URL BUILDER)
    // -------------------------------------------------------------------------
    test(
      'buildRemoteUrl deve construir a URL correta para um pacote comum',
      () {
        final input = ApplicationArtifactInput(
          packageManager: 'npm',
          namespace: 'public',
          packageName: 'axios',
          remoteUrl: 'https://registry.npmjs.org',
          version: '1.6.0',
          fileName: 'axios-1.6.0.tgz',
        );

        final url = npmHandler.buildRemoteUrl(input);

        expect(
          url.toString(),
          'https://registry.npmjs.org/axios/-/axios-1.6.0.tgz',
        );
      },
    );

    test(
      'buildRemoteUrl deve construir a URL correta para um pacote com scope',
      () {
        final input = ApplicationArtifactInput(
          packageManager: 'npm',
          namespace: 'public',
          packageName: '@nestjs/core',
          remoteUrl: 'https://registry.npmjs.org',
          version: '10.0.0',
          fileName: 'core-10.0.0.tgz',
        );

        final url = npmHandler.buildRemoteUrl(input);

        expect(
          url.toString(),
          'https://registry.npmjs.org/@nestjs/core/-/core-10.0.0.tgz',
        );
      },
    );

    // -------------------------------------------------------------------------
    // TESTES DE FLUXO (CACHE / PROXY)
    // -------------------------------------------------------------------------
    test('handle deve retornar artefato local se já existir', () async {
      // Arrange
      final input = ApplicationArtifactInput(
        packageManager: 'npm',
        remoteUrl: 'https://registry.npmjs.org/',
        namespace: 'public',
        packageName: 'axios',
        version: '1.6.0',
      );
      final mockResult = MockArtifactDownloadResult();
      final streamController = StreamController<Uint8List>();
      streamController.add(Uint8List.fromList([1, 2, 3]));
      streamController.close();

      when(() => mockResult.stream).thenAnswer((_) => streamController.stream);

      when(
        () => mockGetArtifactDownloadStreamUsecase.execute(
          namespace: any(named: 'namespace'),
          name: any(named: 'name'),
          version: any(named: 'version'),
        ),
      ).thenAnswer((_) async => mockResult);

      when(() => mockCache.acquireLock(any())).thenAnswer((_) async => true);
      when(() => mockCache.releaseLock(any())).thenAnswer((_) async {});

      // Act
      final stream = await npmHandler.handle(input);

      // Assert
      expect(stream, isNotNull); // 3. CORRIGIDO: Estava isFalse
      expect(await stream.first, equals([1, 2, 3]));

      // Valida se o banco local foi consultado corretamente
      verify(
        () => mockGetArtifactDownloadStreamUsecase.execute(
          namespace: 'public',
          name: 'axios',
          version: '1.6.0',
        ),
      ).called(1);

      // Garante que o fluxo de proxy não foi iniciado
      verifyNever(() => mockCache.acquireLock(any()));
      verifyNever(() => mockHttpClient.stream(any()));
    });

    test(
      'handle deve fazer proxy do artefato se não existir localmente',
      () async {
        // Arrange
        final input = ApplicationArtifactInput(
          packageManager: 'npm',
          namespace: 'public',
          packageName: 'axios',
          remoteUrl: 'https://registry.npmjs.org',
          version: '1.6.0',
          fileName: 'axios-1.6.0.tgz',
        );
        final remoteStream = Stream.fromIterable([
          Uint8List.fromList([4, 5, 6]),
        ]);

        when(
          () => mockGetArtifactDownloadStreamUsecase.execute(
            namespace: any(named: 'namespace'),
            name: any(named: 'name'),
            version: any(named: 'version'),
          ),
        ).thenAnswer((_) async => null);

        when(() => mockCache.acquireLock(any())).thenAnswer((_) async => true);
        when(() => mockCache.releaseLock(any())).thenAnswer((_) async {});

        when(
          () => mockHttpClient.stream(any()),
        ).thenAnswer((_) async => (stream: remoteStream, length: 3));

        when(
          () => mockCreateArtifactUsecase.execute(any(), any()),
        ).thenAnswer((_) async => null);

        // Act
        final stream = await npmHandler.handle(input);

        // Assert
        expect(stream, isNotNull);
        expect(await stream.first, equals([4, 5, 6]));

        verify(
          () => mockGetArtifactDownloadStreamUsecase.execute(
            namespace: 'public',
            name: 'axios',
            version: '1.6.0',
          ),
        ).called(1);

        verify(() => mockCache.acquireLock(any())).called(1);

        verify(
          () => mockHttpClient.stream(npmHandler.buildRemoteUrl(input)),
        ).called(1);

        // A criação do artefato (salvar no MinIO/Banco) é em background
        await Future.delayed(Duration(milliseconds: 100));

        verify(() => mockCreateArtifactUsecase.execute(any(), any())).called(1);
        verify(() => mockCache.releaseLock(any())).called(1);
      },
    );
  });
}
