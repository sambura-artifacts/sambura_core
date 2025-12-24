import 'package:sambura_core/application/exceptions/application_exception.dart';
import 'package:test/test.dart';

void main() {
  group('ApplicationException', () {
    test('deve criar exceção com mensagem', () {
      final exception = ApplicationException('Test message');
      expect(exception.message, 'Test message');
    });

    test('deve ser uma Exception', () {
      final exception = ApplicationException('Test');
      expect(exception, isA<Exception>());
    });
  });

  group('ApiKeyNotFoundException', () {
    test('deve criar exceção com mensagem formatada', () {
      final exception = ApiKeyNotFoundException('test-key-123');
      expect(exception.message, 'API Key "test-key-123" não encontrado.');
    });

    test('deve estender ApplicationException', () {
      final exception = ApiKeyNotFoundException('test-key');
      expect(exception, isA<ApplicationException>());
    });
  });

  group('ListApiKeyNotFoundException', () {
    test('deve criar exceção com mensagem padrão', () {
      final exception = ListApiKeyNotFoundException();
      expect(exception.message, 'Nenhuma API Key foi encontrada.');
    });

    test('deve estender ApplicationException', () {
      final exception = ListApiKeyNotFoundException();
      expect(exception, isA<ApplicationException>());
    });
  });

  group('AccountNotFoundException', () {
    test('deve criar exceção com mensagem formatada', () {
      final exception = AccountNotFoundException('user-123');
      expect(exception.message, 'Seu usuário não foi encontrado.');
    });

    test('deve estender ApplicationException', () {
      final exception = AccountNotFoundException('user-id');
      expect(exception, isA<ApplicationException>());
    });
  });

  group('AccountNotPermissionException', () {
    test('deve criar exceção com mensagem formatada', () {
      final exception = AccountNotPermissionException('user-123');
      expect(
        exception.message,
        'Seu usuário não tem permissão para realizar a ação.',
      );
    });

    test('deve estender ApplicationException', () {
      final exception = AccountNotPermissionException('user-id');
      expect(exception, isA<ApplicationException>());
    });
  });
}
