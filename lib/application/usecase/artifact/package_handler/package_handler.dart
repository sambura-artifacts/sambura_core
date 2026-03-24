import 'dart:async';

import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

abstract class PackageHandler {
  Future<Stream<List<int>>> handle(ArtifactInput input);
  Uri buildRemoteUrl(ArtifactInput input);
}
