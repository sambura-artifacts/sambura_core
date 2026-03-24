import 'package:mocktail/mocktail.dart';
import 'package:sambura_core/application/services/health/health_check_service.dart';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';
import 'package:test/test.dart';

class MockHealthCheckService extends Mock implements HealthCheckService {}

void main() {
  late GetServerHealthUseCase useCase;
  late MockHealthCheckService mockHealthCheckService;

  setUp(() {
    mockHealthCheckService = MockHealthCheckService();
    useCase = GetServerHealthUseCase(mockHealthCheckService);
  });

  group('GetServerHealthUseCase', () {
    test('deve retornar resultado do health check service', () async {
      // Arrange
      final expectedResult = {
        'status': 'HEALTHY',
        'components': {
          'database': {'status': 'HEALTHY', 'elapsed': 10},
        },
      };
      when(
        () => mockHealthCheckService.checkAll(),
      ).thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, equals(expectedResult));
      verify(() => mockHealthCheckService.checkAll()).called(1);
    });

    test('deve propagar erro do health check service', () async {
      // Arrange
      when(
        () => mockHealthCheckService.checkAll(),
      ).thenThrow(Exception('Health check failed'));

      // Act & Assert
      expect(() => useCase.execute(), throwsA(isA<Exception>()));
      verify(() => mockHealthCheckService.checkAll()).called(1);
    });
  });
}
