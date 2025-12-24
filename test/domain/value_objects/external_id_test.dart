import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/value_objects/external_id.dart';
import 'package:test/test.dart';

void main() {
  group('ExternalId', () {
    test('deve aceitar UUID válido', () {
      // Arrange
      const validUuid = '01936d3c-8f4a-7890-b123-456789abcdef';

      // Act
      final externalId = ExternalId(validUuid);

      // Assert
      expect(externalId.value, equals(validUuid));
    });

    test('deve gerar UUID v7 válido com generate', () {
      // Act
      final externalId = ExternalId.generate();

      // Assert
      expect(externalId.value, isNotEmpty);
      expect(externalId.value.length, equals(36));
      expect(externalId.value.contains('-'), isTrue);
    });

    test('deve gerar UUIDs diferentes a cada chamada', () {
      // Act
      final externalId1 = ExternalId.generate();
      final externalId2 = ExternalId.generate();

      // Assert
      expect(externalId1.value, isNot(equals(externalId2.value)));
    });

    test('deve rejeitar UUID inválido', () {
      // Act & Assert
      expect(
        () => ExternalId('invalid-uuid'),
        throwsA(isA<ExternalIdInvalidException>()),
      );

      expect(
        () => ExternalId('123'),
        throwsA(isA<ExternalIdInvalidException>()),
      );

      expect(() => ExternalId(''), throwsA(isA<ExternalIdInvalidException>()));
    });

    test('deve aceitar diferentes versões de UUID', () {
      // Arrange
      const uuidV4 = '550e8400-e29b-41d4-a716-446655440000';
      const uuidV7 = '01936d3c-8f4a-7890-b123-456789abcdef';

      // Act
      final externalId1 = ExternalId(uuidV4);
      final externalId2 = ExternalId(uuidV7);

      // Assert
      expect(externalId1.value, equals(uuidV4));
      expect(externalId2.value, equals(uuidV7));
    });

    test('deve implementar toString corretamente', () {
      // Arrange
      const uuid = '01936d3c-8f4a-7890-b123-456789abcdef';
      final externalId = ExternalId(uuid);

      // Act & Assert
      expect(externalId.toString(), equals(uuid));
    });

    test('deve implementar equality corretamente', () {
      // Arrange
      const uuid = '01936d3c-8f4a-7890-b123-456789abcdef';
      final externalId1 = ExternalId(uuid);
      final externalId2 = ExternalId(uuid);
      final externalId3 = ExternalId.generate();

      // Assert
      expect(externalId1, equals(externalId2));
      expect(externalId1, isNot(equals(externalId3)));
      expect(externalId1.hashCode, equals(externalId2.hashCode));
    });
  });
}
