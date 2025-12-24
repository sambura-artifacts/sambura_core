import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/value_objects/package_name.dart';
import 'package:test/test.dart';

void main() {
  group('PackageName', () {
    group('validação', () {
      test('deve aceitar nome simples válido', () {
        expect(() => PackageName('my-package'), returnsNormally);
        expect(PackageName('my-package').value, equals('my-package'));
      });

      test('deve aceitar nome com escopo válido', () {
        expect(() => PackageName('@scope/package'), returnsNormally);
        expect(PackageName('@scope/package').value, equals('@scope/package'));
      });

      test('deve aceitar nome com números', () {
        expect(() => PackageName('package123'), returnsNormally);
        expect(() => PackageName('@scope123/package456'), returnsNormally);
      });

      test('deve aceitar nome com underscores e hífens', () {
        expect(() => PackageName('my_package-name'), returnsNormally);
        expect(() => PackageName('@my-scope/my_package'), returnsNormally);
      });

      test('deve remover espaços em branco', () {
        final name = PackageName('  my-package  ');
        expect(name.value, equals('my-package'));
      });

      test('deve rejeitar nome vazio', () {
        expect(() => PackageName(''), throwsA(isA<PackageNameException>()));
      });

      test('deve rejeitar nome muito longo', () {
        final longName = 'a' * 215;
        expect(
          () => PackageName(longName),
          throwsA(isA<PackageNameException>()),
        );
      });

      test('deve rejeitar nome com maiúsculas', () {
        expect(
          () => PackageName('MyPackage'),
          throwsA(isA<PackageNameException>()),
        );
      });

      test('deve rejeitar nome com caracteres inválidos', () {
        expect(
          () => PackageName('my package'),
          throwsA(isA<PackageNameException>()),
        );
        expect(
          () => PackageName('my@package'),
          throwsA(isA<PackageNameException>()),
        );
        expect(
          () => PackageName('my#package'),
          throwsA(isA<PackageNameException>()),
        );
      });

      test('deve rejeitar nomes reservados', () {
        expect(
          () => PackageName('node_modules'),
          throwsA(isA<PackageNameException>()),
        );
        expect(
          () => PackageName('favicon.ico'),
          throwsA(isA<PackageNameException>()),
        );
      });

      test('deve rejeitar escopo inválido', () {
        expect(
          () => PackageName('@/package'),
          throwsA(isA<PackageNameException>()),
        );
        expect(
          () => PackageName('@scope'),
          throwsA(isA<PackageNameException>()),
        );
      });
    });

    group('propriedades', () {
      test('isScoped deve retornar true para pacotes com escopo', () {
        final name = PackageName('@scope/package');
        expect(name.isScoped, isTrue);
      });

      test('isScoped deve retornar false para pacotes sem escopo', () {
        final name = PackageName('package');
        expect(name.isScoped, isFalse);
      });

      test('scope deve retornar o escopo correto', () {
        final name = PackageName('@my-scope/package');
        expect(name.scope, equals('@my-scope'));
      });

      test('scope deve retornar string vazia para pacotes sem escopo', () {
        final name = PackageName('package');
        expect(name.scope, equals(''));
      });

      test('nameWithoutScope deve retornar nome sem escopo', () {
        final scopedName = PackageName('@scope/package');
        expect(scopedName.nameWithoutScope, equals('package'));

        final simpleName = PackageName('package');
        expect(simpleName.nameWithoutScope, equals('package'));
      });
    });

    group('igualdade', () {
      test('deve considerar iguais PackageNames com mesmo valor', () {
        final name1 = PackageName('my-package');
        final name2 = PackageName('my-package');

        expect(name1, equals(name2));
        expect(name1.hashCode, equals(name2.hashCode));
      });

      test(
        'deve considerar diferentes PackageNames com valores diferentes',
        () {
          final name1 = PackageName('package1');
          final name2 = PackageName('package2');

          expect(name1, isNot(equals(name2)));
        },
      );

      test('toString deve retornar o valor', () {
        final name = PackageName('@scope/package');
        expect(name.toString(), equals('@scope/package'));
      });
    });
  });
}
