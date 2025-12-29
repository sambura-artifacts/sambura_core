import 'package:sambura_core/domain/entities/entities.dart';

class DownloadResult {
  final ArtifactEntity artifact;
  final Stream<List<int>> stream;

  DownloadResult(this.artifact, this.stream);
}
