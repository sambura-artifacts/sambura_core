import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/value_objects/package_name.dart';
import 'package:test/test.dart';

void main() {
  group('PackageName', () {
    group('validação universal', () {
      test('deve aceitar nome simples (NPM style)', () {
        expect(() => PackageName('my-package'), returnsNormally);
        expect(PackageName('my-package').value, equals('my-package'));
      });

      test('deve aceitar nome com escopo (NPM style)', () {
        expect(() => PackageName('@scope/package'), returnsNormally);
        expect(PackageName('@scope/package').value, equals('@scope/package'));
      });

      test('deve aceitar coordenadas Maven (groupId:artifactId)', () {
        expect(() => PackageName('org.apache.maven:maven-model'), returnsNormally);
        expect(PackageName('org.apache.maven:maven-model').value, equals('org.apache.maven:maven-model'));
      });

      test('deve aceitar nomes com maiúsculas (comum em Maven/NuGet)', () {
        expect(() => PackageName('Newtonsoft.Json'), returnsNormally);
        expect(PackageName('Newtonsoft.Json').value, equals('Newtonsoft.Json'));
      });

      test('deve aceitar nome com números e caracteres especiais permitidos', () {
        expect(() => PackageName('package123'), returnsNormally);
        expect(() => PackageName('my.package_name-123'), returnsNormally);
      });

      test('deve remover espaços em branco', () {
        final name = PackageName('  universal-package  ');
        expect(name.value, equals('universal-package'));
      });

      test('deve rejeitar nome vazio', () {
        expect(() => PackageName(''), throwsA(isA<PackageNameException>()));
      });

      test('deve rejeitar nome excessivamente longo (> 512)', () {
        final longName = 'a' * 513;
        expect(
          () => PackageName(longName),
          throwsA(isA<PackageNameException>()),
        );
      });

      test('deve rejeitar caracteres proibidos (espaços, hashtags, etc)', () {
        expect(() => PackageName('my package'), throwsA(isA<PackageNameException>()));
        expect(() => PackageName('my#package'), throwsA(isA<PackageNameException>()));
        expect(() => PackageName('my!package'), throwsA(isA<PackageNameException>()));
      });
    });

    group('propriedades', () {
      test('isScoped deve retornar true para pacotes com "/" ou ":"', () {
        expect(PackageName('@scope/package').isScoped, isTrue);
        expect(PackageName('group:artifact').isScoped, isTrue);
      });

      test('isScoped deve retornar false para pacotes sem "/" ou ":"', () {
        expect(PackageName('package').isScoped, isFalse);
      });

      test('scope deve retornar o prefixo correto', () {
        expect(PackageName('@my-scope/package').scope, equals('@my-scope'));
        expect(PackageName('org.apache:maven').scope, equals('org.apache'));
      });

      test('nameWithoutScope deve retornar a parte final do nome', () {
        expect(PackageName('@scope/package').nameWithoutScope, equals('package'));
        expect(PackageName('group:artifact').nameWithoutScope, equals('artifact'));
        expect(PackageName('simple-package').nameWithoutScope, equals('simple-package'));
      });
    });

    group('igualdade', () {
      test('deve considerar iguais PackageNames com mesmo valor', () {
        final name1 = PackageName('Package.Name');
        final name2 = PackageName('Package.Name');

        expect(name1, equals(name2));
        expect(name1.hashCode, equals(name2.hashCode));
      });

      test('toString deve retornar o valor', () {
        final name = PackageName('org.sambura:core');
        expect(name.toString(), equals('org.sambura:core'));
      });
    });
  });
}
