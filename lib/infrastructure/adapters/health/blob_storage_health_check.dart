// lib/infrastructure/adapters/health/blob_storage_health_check.dart
import 'package:sambura_core/application/ports/health_check.dart';
import 'package:sambura_core/application/ports/storage_port.dart';

class BlobStorageHealthCheck implements HealthCheckPort {
  final String bucketName;
  final StoragePort _storage;

  BlobStorageHealthCheck(this.bucketName, this._storage);

  @override
  String get name => 'blob_storage_silo';

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Tenta verificar se o bucket existe como teste de conectividade
      final exists = await _storage.bucketExists(bucketName);
      stopwatch.stop();

      if (exists) {
        return HealthCheckResult.healthy(name, stopwatch.elapsed);
      }
      return HealthCheckResult.unhealthy(
        name,
        stopwatch.elapsed,
        'Bucket $bucketName não encontrado',
      );
    } catch (e) {
      stopwatch.stop();
      return HealthCheckResult.unhealthy(name, stopwatch.elapsed, e.toString());
    }
  }
}
