import 'package:sambura_core/infrastructure/api/controller/artifact/npm_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/maven_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/pypi_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/nuget_controller.dart';
import 'package:sambura_core/infrastructure/api/controller/artifact/docker_controller.dart';
import 'package:shelf_router/shelf_router.dart';

class PackageManagerRouter {
  final NpmController _npmController;
  final MavenController _mavenController;
  final PypiController _pypiController;
  final NugetController _nugetController;
  final DockerController _dockerController;

  PackageManagerRouter(
    this._npmController,
    this._mavenController,
    this._pypiController,
    this._nugetController,
    this._dockerController,
  );

  Router get router {
    final router = Router();

    // 4. NPM Proxy Routes
    router.get(
      '/npm/<repo>/<package|.*>/-/<filename>',
      _npmController.downloadTarball,
    );
    router.get(
      '/npm/<repo>/<packageName|.*>',
      _npmController.getPackageMetadata,
    );

    // 5. Maven Routes
    router.get(
      '/maven/<repo>/<groupId>/<artifactId>/<version>/<filename>',
      _mavenController.downloadArtifact,
    );
    router.get(
      '/maven/<repo>/<groupId>/<artifactId>/maven-metadata.xml',
      _mavenController.getMetadata,
    );

    // 6. PyPI Routes
    router.get(
      '/pypi/<repo>/simple/<package>/',
      _pypiController.getSimpleMetadata,
    );
    router.get(
      '/pypi/<repo>/packages/<path|.*>',
      _pypiController.downloadArtifact,
    );

    // 7. NuGet Routes
    router.get('/nuget/<repo>/v3/index.json', _nugetController.getServiceIndex);
    router.get(
      '/nuget/<repo>/v3-flatcontainer/<package>/<version>/<filename>',
      _nugetController.downloadPackage,
    );
    router.get('/nuget/<repo>/<any|.*>', _nugetController.proxyResource);

    // 8. Docker Registry Routes
    router.get('/docker/<repo>/v2/', _dockerController.checkApi);
    router.get(
      '/docker/<repo>/v2/<name|.*>/manifests/<reference>',
      _dockerController.getManifest,
    );
    router.get(
      '/docker/<repo>/v2/<name|.*>/blobs/<digest>',
      _dockerController.downloadBlob,
    );

    return router;
  }
}
