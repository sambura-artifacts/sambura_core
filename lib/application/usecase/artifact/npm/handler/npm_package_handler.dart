import 'dart:async';
import 'dart:typed_data';

import 'package:sambura_core/application/barrel.dart';

abstract class NpmPackageHandler {
  Future<Stream<Uint8List>> handle(ApplicationArtifactInput input);
  Uri buildRemoteUrl(ApplicationArtifactInput input);
}
