import 'package:sambura_core/application/ports/barrel.dart';

class PostgresHealthCheck implements HealthCheckPort {
  final dynamic _db;
  @override
  String get name => 'postgres';

  PostgresHealthCheck(this._db);

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _db.query('SELECT 1');
      return HealthCheckResult.healthy(name, stopwatch.elapsed);
    } catch (e) {
      return HealthCheckResult.unhealthy(name, stopwatch.elapsed, e.toString());
    }
  }
}
