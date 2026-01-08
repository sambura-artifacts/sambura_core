import 'dart:async';
import 'dart:typed_data';
import 'package:mocktail/mocktail.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/infrastructure/artifact/api/dtos/artifact_input.dart';
import 'package:test/test.dart';

// Seus imports...
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/infrastructure/infrastructure.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';

// Mocks de Comportamento
class MockRegisterCompliance extends Mock
    implements RegisterComplianceArtifactUseCase {}

class MockCreateArtifact extends Mock implements CreateArtifactUsecase {}

class MockHttpClientPort extends Mock implements HttpClientPort {}

class MockMetricsPort extends Mock implements MetricsPort {}

class MockCachePort extends Mock implements CachePort {}

void main() {
  late DownloadArtifactTarballUseCase usecase;
  late MockRegisterCompliance registerCompliance;
  late MockCreateArtifact createArtifact;
  late GetArtifactDownloadStreamUsecase getArtifactStream;
  late MockHttpClientPort httpClient;
  late MockCachePort cache;
  late MockMetricsPort metrics;

  // Repositórios In-Memory (Estado persistente para o teste)
  late InMemoryArtifactRepository artifactRepo;
  late InMemoryBlobRepository blobRepo;
  late InMemoryCacheAdapter cacheAdapter;

  setUp(() {
    registerCompliance = MockRegisterCompliance();
    createArtifact = MockCreateArtifact();
    httpClient = MockHttpClientPort();
    cache = MockCachePort();
    metrics = MockMetricsPort();

    artifactRepo = InMemoryArtifactRepository();
    blobRepo = InMemoryBlobRepository();
    cacheAdapter = InMemoryCacheAdapter();

    getArtifactStream = GetArtifactDownloadStreamUsecase(
      artifactRepo,
      blobRepo,
      cacheAdapter,
    );

    usecase = DownloadArtifactTarballUseCase(
      httpClient,
      createArtifact,
      getArtifactStream,
      registerCompliance,
      cache,
      metrics,
    );

    // Necessário para o mocktail entender o ArtifactInput nos any()
    registerFallbackValue(
      ArtifactInput(
        repositoryName: '',
        packageName: '',
        version: '',
        namespace: '',
        path: '',
      ),
    );
    registerFallbackValue(Stream<List<int>>.empty());
  });

  test(
    'deve disparar fluxo de compliance após persistência bem-sucedida',
    () async {
      // Arrange
      final input = ArtifactInput(
        repositoryName: 'npm-proxy',
        packageName: 'sambura-utils',
        version: '1.0.0',
        namespace: 'core',
        path: 'path-valid',
      );

      final mockBytes = Uint8List.fromList([1, 2, 3, 4]);

      // 1. Simula o Lock do Cache
      when(
        () => cache.acquireLock(any(), duration: any(named: 'duration')),
      ).thenAnswer((_) async => true);
      when(() => cache.releaseLock(any())).thenAnswer((_) async => {});

      // 2. Simula resposta do Proxy Externo
      when(() => httpClient.stream(any())).thenAnswer(
        (_) async =>
            (stream: Stream.value(mockBytes), length: mockBytes.length),
      );

      // 3. Simula sucesso na criação do artefato
      when(
        () => createArtifact.execute(any(), any()),
      ).thenAnswer((_) async => null);

      // 4. Prepara o estado In-Memory para o GetArtifactDownloadStreamUsecase
      // Salvamos o hash no repositório de artefatos
      final artifact = ArtifactEntity.restore(
        id: 1,
        externalId: 'ext-1',
        packageName: input.packageName,
        namespace: input.namespace,
        version: input.version,
        packageId: 1,
        blobId: 1,
        path: 'path-valid',
        createdAt: DateTime.now(),
      );

      final blob = BlobEntity.restore(
        id: 1,
        hash: 'mock-hash',
        size: mockBytes.length,
        mime: 'application/octet-stream',
        createdAt: DateTime.now(),
      );
      await blobRepo.save(blob);

      await artifactRepo.save(artifact);

      // Salvamos o conteúdo físico no repositório de blobs
      await blobRepo.saveContent('mock-hash', mockBytes);

      when(() => metrics.incrementCounter(any())).thenAnswer((_) => {});
      when(
        () => metrics.observeHistogram(
          any(),
          any(),
          labels: any(named: 'labels'),
        ),
      ).thenAnswer((_) => {});

      // Act
      await usecase.executeProxyStream(
        remoteUrl: 'https://registry.npmjs.org/artifact.tgz',
        input: input,
      );

      // Aguarda processamento assíncrono (unawaited)
      await Future.delayed(const Duration(milliseconds: 150));

      // Assert
      verify(
        () => registerCompliance.execute(
          name: 'sambura-utils',
          version: '1.0.0',
          filename: 'sambura-utils-1.0.0.tgz',
          bytes: any(named: 'bytes'),
        ),
      ).called(1);
    },
  );
}
