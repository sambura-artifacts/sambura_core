abstract class HealthCheckPort {
  String get name;
  Future<HealthCheckResult> check();
}

class HealthCheckResult {
  final String name;
  final bool isHealthy;
  final String? message;
  final Duration elapsed; // Unificando 'latency' e 'elapsed' para 'elapsed'
  final Map<String, dynamic>? details;

  HealthCheckResult({
    required this.name,
    required this.isHealthy,
    required this.elapsed,
    this.message,
    this.details,
  });

  // Fábrica para status positivo
  factory HealthCheckResult.healthy(String name, Duration elapsed) =>
      HealthCheckResult(name: name, isHealthy: true, elapsed: elapsed);

  // Fábrica para status negativo
  factory HealthCheckResult.unhealthy(
    String name,
    Duration elapsed,
    String message,
  ) => HealthCheckResult(
    name: name,
    isHealthy: false,
    elapsed: elapsed,
    message: message,
  );

  Map<String, dynamic> toMap() => {
    'status': isHealthy ? 'UP' : 'DOWN',
    'latency_ms': elapsed.inMilliseconds,
    if (message != null) 'message': message,
    if (details != null) 'details': details,
  };
}
