import 'package:sambura_core/domain/value_objects/version.dart';
import 'package:test/test.dart';

void main() {
  group('Version', () {
    group('criação', () {
      test('deve criar versão válida simples', () {
        final version = Version.create('1.0.0');
        expect(version.value, equals('1.0.0'));
        expect(version.major, equals(1));
        expect(version.minor, equals(0));
        expect(version.patch, equals(0));
        expect(version.preRelease, isNull);
      });

      test('deve criar versão com números diferentes', () {
        final version = Version.create('2.5.13');
        expect(version.major, equals(2));
        expect(version.minor, equals(5));
        expect(version.patch, equals(13));
      });

      test('deve criar versão com pré-release', () {
        final version = Version.create('1.0.0-alpha');
        expect(version.major, equals(1));
        expect(version.minor, equals(0));
        expect(version.patch, equals(0));
        expect(version.preRelease, equals('alpha'));
      });

      test('deve criar versão com pré-release complexo', () {
        final version = Version.create('1.0.0-beta.1');
        expect(version.preRelease, equals('beta.1'));
      });

      test('deve rejeitar versão vazia', () {
        expect(() => Version.create(''), throwsArgumentError);
      });

      test('deve rejeitar versão inválida', () {
        expect(() => Version.create('1.0'), throwsArgumentError);
        expect(() => Version.create('1'), throwsArgumentError);
        expect(() => Version.create('a.b.c'), throwsArgumentError);
        expect(() => Version.create('1.0.0.0'), throwsArgumentError);
      });

      test('unsafe deve aceitar versão válida', () {
        final version = Version.unsafe('1.2.3');
        expect(version.value, equals('1.2.3'));
        expect(version.major, equals(1));
      });

      test('unsafe deve aceitar versão inválida sem lançar erro', () {
        expect(() => Version.unsafe('invalid'), returnsNormally);
        final version = Version.unsafe('invalid');
        expect(version.value, equals('invalid'));
      });
    });

    group('propriedades', () {
      test('isPreRelease deve retornar true para versões pré-release', () {
        final version = Version.create('1.0.0-alpha');
        expect(version.isPreRelease, isTrue);
      });

      test('isPreRelease deve retornar false para versões estáveis', () {
        final version = Version.create('1.0.0');
        expect(version.isPreRelease, isFalse);
      });

      test('isStable deve retornar true para versões >= 1.0.0', () {
        expect(Version.create('1.0.0').isStable, isTrue);
        expect(Version.create('2.5.3').isStable, isTrue);
      });

      test('isStable deve retornar false para versões < 1.0.0', () {
        expect(Version.create('0.1.0').isStable, isFalse);
        expect(Version.create('0.9.9').isStable, isFalse);
      });

      test('isStable deve retornar false para pré-release', () {
        expect(Version.create('1.0.0-alpha').isStable, isFalse);
      });
    });

    group('comparação', () {
      test('deve comparar versões por major', () {
        final v1 = Version.create('1.0.0');
        final v2 = Version.create('2.0.0');

        expect(v1 < v2, isTrue);
        expect(v2 > v1, isTrue);
        expect(v1.compareTo(v2), equals(-1));
      });

      test('deve comparar versões por minor quando major é igual', () {
        final v1 = Version.create('1.0.0');
        final v2 = Version.create('1.5.0');

        expect(v1 < v2, isTrue);
        expect(v2 > v1, isTrue);
      });

      test(
        'deve comparar versões por patch quando major e minor são iguais',
        () {
          final v1 = Version.create('1.0.0');
          final v2 = Version.create('1.0.5');

          expect(v1 < v2, isTrue);
          expect(v2 > v1, isTrue);
        },
      );

      test('deve considerar pré-release menor que versão estável', () {
        final v1 = Version.create('1.0.0-alpha');
        final v2 = Version.create('1.0.0');

        expect(v1 < v2, isTrue);
        expect(v2 > v1, isTrue);
      });

      test('deve comparar pré-releases lexicograficamente', () {
        final v1 = Version.create('1.0.0-alpha');
        final v2 = Version.create('1.0.0-beta');

        expect(v1 < v2, isTrue);
      });

      test('deve considerar versões iguais', () {
        final v1 = Version.create('1.2.3');
        final v2 = Version.create('1.2.3');

        expect(v1 == v2, isTrue);
        expect(v1.compareTo(v2), equals(0));
      });

      test('deve suportar operadores de comparação', () {
        final v1 = Version.create('1.0.0');
        final v2 = Version.create('2.0.0');
        final v3 = Version.create('1.0.0');

        expect(v1 < v2, isTrue);
        expect(v2 > v1, isTrue);
        expect(v1 <= v3, isTrue);
        expect(v1 >= v3, isTrue);
      });
    });

    group('serialização', () {
      test('toString deve retornar o valor', () {
        final version = Version.create('1.2.3-beta.1');
        expect(version.toString(), equals('1.2.3-beta.1'));
      });
    });

    group('igualdade', () {
      test('deve considerar iguais versions com mesmo valor', () {
        final v1 = Version.create('1.2.3');
        final v2 = Version.create('1.2.3');

        expect(v1, equals(v2));
        expect(v1.hashCode, equals(v2.hashCode));
      });

      test('deve considerar diferentes versions com valores diferentes', () {
        final v1 = Version.create('1.2.3');
        final v2 = Version.create('1.2.4');

        expect(v1, isNot(equals(v2)));
      });
    });
  });
}
