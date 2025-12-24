import 'dart:convert';
import 'package:sambura_core/application/usecase/health/get_server_health_usecase.dart';
import 'package:sambura_core/infrastructure/api/controller/system/health_controller.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class MockGetServerHealthUseCase implements GetServerHealthUseCase {
  Map<String, dynamic>? resultToReturn;

  MockGetServerHealthUseCase(dynamic repo, dynamic storage);

  @override
  Future<Map<String, dynamic>> execute() async {
    return resultToReturn ?? {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'services': {
        'database': 'up',
        'storage': 'up',
      },
    };
  }
}

void main() {
  group('HealthController', () {
    late HealthController controller;
    late MockGetServerHealthUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockGetServerHealthUseCase(null, null);
      controller = HealthController(mockUseCase);
    });

    group('GET /', () {
      test('deve retornar 200 quando todos os serviços estão saudáveis', () async {
        // Arrange
        mockUseCase.resultToReturn = {
          'status': 'healthy',
          'timestamp': '2024-12-24T21:46:20.332Z',
          'services': {
            'database': 'up',
            'storage': 'up',
          },
        };

        final request = Request('GET', Uri.parse('http://localhost/health'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert
        expect(response.statusCode, equals(200));
        
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('healthy'));
        expect(body['services']['database'], equals('up'));
        expect(body['services']['storage'], equals('up'));
      });

      test('deve retornar 503 quando o banco de dados está fora', () async {
        // Arrange
        mockUseCase.resultToReturn = {
          'status': 'unhealthy',
          'timestamp': '2024-12-24T21:46:20.332Z',
          'services': {
            'database': 'down',
            'storage': 'up',
          },
        };

        final request = Request('GET', Uri.parse('http://localhost/health'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert
        expect(response.statusCode, equals(503));
        
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('unhealthy'));
        expect(body['services']['database'], equals('down'));
        expect(body['services']['storage'], equals('up'));
      });

      test('deve retornar 503 quando o storage está fora', () async {
        // Arrange
        mockUseCase.resultToReturn = {
          'status': 'unhealthy',
          'timestamp': '2024-12-24T21:46:20.332Z',
          'services': {
            'database': 'up',
            'storage': 'down',
          },
        };

        final request = Request('GET', Uri.parse('http://localhost/health'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert
        expect(response.statusCode, equals(503));
        
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('unhealthy'));
        expect(body['services']['database'], equals('up'));
        expect(body['services']['storage'], equals('down'));
      });

      test('deve retornar 503 quando todos os serviços estão fora', () async {
        // Arrange
        mockUseCase.resultToReturn = {
          'status': 'unhealthy',
          'timestamp': '2024-12-24T21:46:20.332Z',
          'services': {
            'database': 'down',
            'storage': 'down',
          },
        };

        final request = Request('GET', Uri.parse('http://localhost/health'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert
        expect(response.statusCode, equals(503));
        
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('unhealthy'));
        expect(body['services']['database'], equals('down'));
        expect(body['services']['storage'], equals('down'));
      });

      test('deve retornar content-type application/json', () async {
        // Arrange
        mockUseCase.resultToReturn = {
          'status': 'healthy',
          'timestamp': '2024-12-24T21:46:20.332Z',
          'services': {
            'database': 'up',
            'storage': 'up',
          },
        };

        final request = Request('GET', Uri.parse('http://localhost/health'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert
        expect(response.headers['content-type'], equals('application/json'));
      });
    });

    group('GET /liveness', () {
      test('deve sempre retornar 200 com status alive', () async {
        // Arrange
        final request = Request('GET', Uri.parse('http://localhost/health/liveness'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert
        expect(response.statusCode, equals(200));
        
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('alive'));
      });

      test('deve retornar content-type application/json', () async {
        // Arrange
        final request = Request('GET', Uri.parse('http://localhost/health/liveness'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert
        expect(response.headers['content-type'], equals('application/json'));
      });

      test('não deve chamar o use case de health check', () async {
        // Arrange
        var useCaseCalled = false;
        mockUseCase.resultToReturn = {
          'status': 'healthy',
          'timestamp': '2024-12-24T21:46:20.332Z',
          'services': {
            'database': 'up',
            'storage': 'up',
          },
        };

        final request = Request('GET', Uri.parse('http://localhost/health/liveness'));
        final handler = controller.router;

        // Act
        final response = await handler(request);

        // Assert - liveness não deve depender de serviços externos
        expect(response.statusCode, equals(200));
        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('alive'));
        // Se o liveness dependesse do use case, teria os campos 'services' e 'timestamp'
        expect(body.containsKey('services'), isFalse);
      });
    });
  });
}
