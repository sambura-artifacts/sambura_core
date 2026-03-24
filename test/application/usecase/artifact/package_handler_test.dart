import 'dart:async';
import 'dart:typed_data';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/maven_handler.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class MockHttpClient extends Mock implements HttpClientPort {}

class MockCreateArtifactUsecase extends Mock implements CreateArtifactUsecase {}

class MockGetArtifactDownloadStreamUsecase extends Mock
    implements GetArtifactDownloadStreamUsecase {}

class MockCache extends Mock implements CachePort {}

class MockMetrics extends Mock implements MetricsPort {}

class MockArtifactDownloadResult extends Mock
    implements ArtifactDownloadResult {}

void main() {
  late MavenHandler mavenHandler;
  late MockHttpClient mockHttpClient;
  late MockCreateArtifactUsecase mockCreateArtifactUsecase;
  late MockGetArtifactDownloadStreamUsecase
  mockGetArtifactDownloadStreamUsecase;
  late MockCache mockCache;
  late MockMetrics mockMetrics;

  setUpAll(() {
    registerFallbackValue(
      ArtifactInput(namespace: '', packageName: '', version: ''),
    );
    registerFallbackValue(Stream<List<int>>.empty());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockCreateArtifactUsecase = MockCreateArtifactUsecase();
    mockGetArtifactDownloadStreamUsecase =
        MockGetArtifactDownloadStreamUsecase();
    mockCache = MockCache();
    mockMetrics = MockMetrics();

    mavenHandler = MavenHandler(
      mockHttpClient,
      mockCreateArtifactUsecase,
      mockGetArtifactDownloadStreamUsecase,
      mockCache,
      mockMetrics,
    );
  });

  group('MavenHandler', () {
    test('buildRemoteUrl deve construir a URL correta', () {
      final input = ArtifactInput(
        namespace: 'central',
        packageName: 'org.apache.commons:commons-lang3',
        version: '3.12.0',
        fileName: 'commons-lang3-3.12.0.jar',
        metadata: {
          'groupId': 'org.apache.commons',
          'artifactId': 'commons-lang3',
        },
      );

      final url = mavenHandler.buildRemoteUrl(input);

      expect(
        url.toString(),
        'https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar',
      );
    });

    test('handle deve retornar artefato local se já existir', () async {
      // Arrange
      final input = ArtifactInput(
        namespace: 'central',
        packageName: 'test',
        version: '1.0',
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

      // Act
      final stream = await mavenHandler.handle(input);

      // Assert
      expect(stream, isNotNull);
      expect(await stream.first, equals([1, 2, 3]));
      verify(
        () => mockGetArtifactDownloadStreamUsecase.execute(
          namespace: 'central',
          name: 'test',
          version: '1.0',
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
        final input = ArtifactInput(
          namespace: 'central',
          packageName: 'org.apache.commons:commons-lang3',
          version: '3.12.0',
          fileName: 'commons-lang3-3.12.0.jar',
          metadata: {
            'groupId': 'org.apache.commons',
            'artifactId': 'commons-lang3',
          },
        );
        final remoteStream = Stream.fromIterable([
          Uint8List.fromList([4, 5, 6]),
        ]);

        // Artefato não existe localmente
        when(
          () => mockGetArtifactDownloadStreamUsecase.execute(
            namespace: any(named: 'namespace'),
            name: any(named: 'name'),
            version: any(named: 'version'),
          ),
        ).thenAnswer((_) async => null);

        // Lock é adquirido com sucesso
        when(() => mockCache.acquireLock(any())).thenAnswer((_) async => true);
        when(() => mockCache.releaseLock(any())).thenAnswer((_) async {});

        // HttpClient retorna um stream
        when(
          () => mockHttpClient.stream(any()),
        ).thenAnswer((_) async => (stream: remoteStream, length: 3));

        // CreateArtifactUsecase funciona
        when(
          () => mockCreateArtifactUsecase.execute(any(), any()),
        ).thenAnswer((_) async => null);

        // Act
        final stream = await mavenHandler.handle(input);

        // Assert
        expect(stream, isNotNull);
        expect(await stream.first, equals([4, 5, 6]));

        verify(
          () => mockGetArtifactDownloadStreamUsecase.execute(
            namespace: 'central',
            name: 'org.apache.commons:commons-lang3',
            version: '3.12.0',
          ),
        ).called(1);
        verify(() => mockCache.acquireLock(any())).called(1);
        verify(
          () => mockHttpClient.stream(mavenHandler.buildRemoteUrl(input)),
        ).called(1);
        // A criação do artefato é chamada em background (unawaited), então esperamos um pouco
        await Future.delayed(Duration(milliseconds: 100));
        verify(() => mockCreateArtifactUsecase.execute(any(), any())).called(1);
        verify(() => mockCache.releaseLock(any())).called(1);
      },
    );
  });
}
