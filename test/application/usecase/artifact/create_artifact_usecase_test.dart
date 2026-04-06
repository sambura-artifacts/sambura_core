import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class MockArtifactRepository extends Mock implements ArtifactRepository {}

class MockPackageRepository extends Mock implements PackageRepository {}

class MockBlobRepository extends Mock implements BlobRepository {}

class MockNamespaceRepository extends Mock implements NamespaceRepository {}

class FakeArtifactEntity extends Fake implements ArtifactEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(Stream<List<int>>.empty());
    registerFallbackValue(FakeArtifactEntity());
  });

  late CreateArtifactUsecase useCase;
  late MockArtifactRepository mockArtifactRepository;
  late MockPackageRepository mockPackageRepository;
  late MockBlobRepository mockBlobRepository;
  late MockNamespaceRepository mockNamespaceRepository;

  setUp(() {
    mockArtifactRepository = MockArtifactRepository();
    mockPackageRepository = MockPackageRepository();
    mockBlobRepository = MockBlobRepository();
    mockNamespaceRepository = MockNamespaceRepository();

    useCase = CreateArtifactUsecase(
      mockArtifactRepository,
      mockPackageRepository,
      mockBlobRepository,
      mockNamespaceRepository,
    );
  });

  group('CreateArtifactUsecase', () {
    test('deve criar artefato com sucesso', () async {
      // Arrange
      final input = InfraestructureArtifactInput(
        packageManager: 'npm',
        remoteUrl: 'npm-remote-url',
        namespace: 'test-repo',
        packageName: 'test-package',
        version: '1.0.0',
        fileName: '/path/to/artifact',
      );
      final fileStream = Stream.fromIterable([
        <int>[1, 2, 3],
      ]);
      final repo = NamespaceEntity.fromMap({
        'id': 1,
        'package_manager': 'npm',
        'name': 'test-repo',
        'escope': 'test-escope',
        'is_public': true,
        'remote_url': 'npm-remote-url',
      });
      final blob = BlobEntity.create(
        hash: 'hash123',
        size: 100,
        mime: 'application/octet-stream',
      );
      final package = PackageEntity.fromMap({
        'id': 1,
        'name': 'test-package',
        'repository_id': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      final artifact = ArtifactEntity.create(
        packageId: 1,
        packageName: 'test-package',
        namespace: 'test-namespace',
        version: '1.0.0',
        path: '/path/to/artifact',
        blob: blob,
      );

      when(
        () => mockNamespaceRepository.getByName('test-repo'),
      ).thenAnswer((_) async => repo);
      when(
        () => mockBlobRepository.saveFromStream(any()),
      ).thenAnswer((_) async => blob);
      when(
        () => mockPackageRepository.ensurePackage(
          namespaceId: 1,
          name: 'test-package',
        ),
      ).thenAnswer((_) async => package);
      when(
        () => mockArtifactRepository.save(any()),
      ).thenAnswer((_) async => artifact);

      // Act
      final result = await useCase.execute(input, fileStream);
      // Assert
      expect(result, isNotNull);
      expect(result!.version.toString(), '1.0.0');
      verify(() => mockNamespaceRepository.getByName('test-repo')).called(1);
      verify(() => mockBlobRepository.saveFromStream(any())).called(1);
      verify(
        () => mockPackageRepository.ensurePackage(
          namespaceId: 1,
          name: 'test-package',
        ),
      ).called(1);
      verify(() => mockArtifactRepository.save(any())).called(1);
    });

    test(
      'deve lançar RepositoryNotFoundException quando repositório não existe',
      () async {
        // Arrange
        final input = InfraestructureArtifactInput(
          namespace: 'non-existent-repo',
          packageName: 'test-package',
          version: '1.0.0',
          fileName: '/path/to/artifact',
        );
        final fileStream = Stream.fromIterable([
          <int>[1, 2, 3],
        ]);

        when(
          () => mockNamespaceRepository.getByName('non-existent-repo'),
        ).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => useCase.execute(input, fileStream),
          throwsA(isA<RepositoryNotFoundException>()),
        );
        verify(
          () => mockNamespaceRepository.getByName('non-existent-repo'),
        ).called(1);
      },
    );
  });
}
