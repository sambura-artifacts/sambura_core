import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class MockNpmDownloadArtifactUsecase extends Mock
    implements NpmDownloadArtifactUsecase {}

class MockNpmGetPackageMetadataUseCase extends Mock
    implements NpmGetPackageMetadataUseCase {}

class MockNpmSecurityAdvisoryConsultingUsecase extends Mock
    implements NpmSecurityAdvisoryConsultingUsecase {}

void main() {
  test(
    'DependencyInjection.configureNpmControllers should initialize NPM-specific controllers',
    () {
      final di = DependencyInjection();

      di.configureNpmControllers(
        npmDownloadArtifactUsecase: MockNpmDownloadArtifactUsecase(),
        npmGetPackageMetadataUseCase: MockNpmGetPackageMetadataUseCase(),
        npmSecurityAdvisoryConsultingUsecase:
            MockNpmSecurityAdvisoryConsultingUsecase(),
      );

      expect(
        di.npmControllerDownloadTarball,
        isA<NpmControllerDownloadTarball>(),
      );
      expect(di.npmControllerGetMetadata, isA<NpmControllerGetMetadata>());
      expect(
        di.npmControllerSecurityAdvisoryConsulting,
        isA<NpmControllerSecurityAdvisoryConsulting>(),
      );
    },
  );
}
