abstract class MetricsPort {
  void reportHealthStatus(bool isAllHealthy);
  void reportComponentStatus(String name, bool isHealthy, Duration latency);
  void recordAuthCache(String result, String type);

  void recordViolation(String reason);
  void recordAuthFailure(String type);
  void updateBlockedIpsCount(int count);
  void recordProxyLatency(String packageName, double ms);

  void recordHttpDuration(
    String method,
    String path,
    int status,
    double durationSeconds,
  );

  void incrementCounter(String name);
  void observeHistogram(
    String name,
    double value, {
    Map<String, String>? labels,
  });
}
