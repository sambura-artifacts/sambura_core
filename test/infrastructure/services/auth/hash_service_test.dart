import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:test/test.dart';

void main() {
  group('HashService', () {
    late HashService hashService;

    setUp(() {
      hashService = HashService('test-pepper');
    });

    test('deve gerar hash de senha', () {
      final password = 'my-password-123';
      final hashed = hashService.hashPassword(password);

      expect(hashed, isNotEmpty);
      expect(hashed, isNot(equals(password)));
      expect(hashed.length, greaterThan(20));
    });

    test('deve gerar hashes diferentes para a mesma senha', () {
      final password = 'my-password-123';
      final hash1 = hashService.hashPassword(password);
      final hash2 = hashService.hashPassword(password);

      expect(hash1, isNot(equals(hash2)));
    });

    test('deve verificar senha correta', () {
      final password = 'my-password-123';
      final hashed = hashService.hashPassword(password);

      final result = hashService.verify(password, hashed);

      expect(result, isTrue);
    });

    test('deve rejeitar senha incorreta', () {
      final password = 'my-password-123';
      final wrongPassword = 'wrong-password';
      final hashed = hashService.hashPassword(password);

      final result = hashService.verify(wrongPassword, hashed);

      expect(result, isFalse);
    });

    test('deve usar pepper na geração do hash', () {
      final hashService1 = HashService('pepper1');
      final hashService2 = HashService('pepper2');

      final password = 'same-password';
      final hash1 = hashService1.hashPassword(password);
      final hash2 = hashService2.hashPassword(password);

      // Different peppers should result in hashes that don't verify with each other
      expect(hashService2.verify(password, hash1), isFalse);
      expect(hashService1.verify(password, hash2), isFalse);
    });

    test('deve usar pepper na verificação', () {
      final password = 'my-password';
      final hashed = hashService.hashPassword(password);

      final otherHashService = HashService('different-pepper');
      final result = otherHashService.verify(password, hashed);

      expect(result, isFalse);
    });
  });
}
