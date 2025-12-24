import 'package:sambura_core/application/ports/storage_port.dart';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:test/test.dart';

class MockArtifactRepository implements ArtifactRepository {
  bool isHealthyValue = true;

  @override
  Future<bool> isHealthy() async {
    return isHealthyValue;
  }

  // Implementar outros métodos obrigatórios do ArtifactRepository
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStoragePort implements StoragePort {
  bool isHealthyValue = true;

  @override
  Future<bool> isHealthy() async {
    return isHealthyValue;
  }

  // Implementar outros métodos obrigatórios do StoragePort
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GetServerHealthUseCase', () {
    late GetServerHealthUseCase usecase;
    late MockArtifactRepository mockRepo;
    late MockStoragePort mockStorage;

    setUp(() {
      mockRepo = MockArtifactRepository();
      mockStorage = MockStoragePort();
      usecase = GetServerHealthUseCase(mockRepo, mockStorage);
    });

    test('deve retornar status healthy quando todos os serviços estão funcionando', () async {
      // Arrange
      mockRepo.isHealthyValue = true;
      mockStorage.isHealthyValue = true;

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result['status'], equals('healthy'));
      expect(result['services']['database'], equals('up'));
      expect(result['services']['storage'], equals('up'));
      expect(result['timestamp'], isNotNull);
    });

    test('deve retornar status unhealthy quando o banco de dados está fora', () async {
      // Arrange
      mockRepo.isHealthyValue = false;
      mockStorage.isHealthyValue = true;

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result['status'], equals('unhealthy'));
      expect(result['services']['database'], equals('down'));
      expect(result['services']['storage'], equals('up'));
      expect(result['timestamp'], isNotNull);
    });

    test('deve retornar status unhealthy quando o storage está fora', () async {
      // Arrange
      mockRepo.isHealthyValue = true;
      mockStorage.isHealthyValue = false;

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result['status'], equals('unhealthy'));
      expect(result['services']['database'], equals('up'));
      expect(result['services']['storage'], equals('down'));
      expect(result['timestamp'], isNotNull);
    });

    test('deve retornar status unhealthy quando todos os serviços estão fora', () async {
      // Arrange
      mockRepo.isHealthyValue = false;
      mockStorage.isHealthyValue = false;

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result['status'], equals('unhealthy'));
      expect(result['services']['database'], equals('down'));
      expect(result['services']['storage'], equals('down'));
      expect(result['timestamp'], isNotNull);
    });

    test('deve incluir timestamp no formato ISO 8601', () async {
      // Arrange
      mockRepo.isHealthyValue = true;
      mockStorage.isHealthyValue = true;

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result['timestamp'], isNotNull);
      expect(result['timestamp'], isA<String>());
      // Verificar se o timestamp é válido
      expect(() => DateTime.parse(result['timestamp']), returnsNormally);
    });

    test('deve retornar estrutura correta do resultado', () async {
      // Arrange
      mockRepo.isHealthyValue = true;
      mockStorage.isHealthyValue = true;

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result.keys, containsAll(['status', 'timestamp', 'services']));
      expect(result['services'], isA<Map<String, dynamic>>());
      expect(result['services'].keys, containsAll(['database', 'storage']));
    });
  });
}
