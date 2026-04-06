import 'package:sambura_core/domain/barrel.dart';

class DownloadResult {
  final ArtifactEntity artifact;
  final Stream<List<int>> stream;

  DownloadResult(this.artifact, this.stream);
}
