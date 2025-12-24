import 'package:sambura_core/application/ports/storage_port.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';

class GetServerHealthUseCase {
  final ArtifactRepository _repo;
  final StoragePort _storage;

  GetServerHealthUseCase(this._repo, this._storage);

  Future<Map<String, dynamic>> execute() async {
    final dbOk = await _repo.isHealthy();
    final storageOk = await _storage.isHealthy();

    return {
      'status': (dbOk && storageOk) ? 'healthy' : 'unhealthy',
      'timestamp': DateTime.now().toIso8601String(),
      'services': {
        'database': dbOk ? 'up' : 'down',
        'storage': storageOk ? 'up' : 'down',
      },
    };
  }
}
