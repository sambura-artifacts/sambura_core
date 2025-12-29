import 'package:sambura_core/application/health/ports/ports.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';

class RedisHealthCheck implements HealthCheckPort {
  final CachePort _redis;
  @override
  String get name => 'redis';

  RedisHealthCheck(this._redis);

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _redis.isHealthy();
      return HealthCheckResult.healthy(name, stopwatch.elapsed);
    } catch (e) {
      return HealthCheckResult.unhealthy(
        name,
        stopwatch.elapsed,
        'Redis unreachable',
      );
    }
  }
}
