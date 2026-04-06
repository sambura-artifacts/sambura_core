abstract class CompositionAnalysisPort {
  Future<void> analyze({
    required String packageName,
    required String version,
    required String projectType, // ex: 'maven', 'npm'
    required List<int>
    fileBytes, // Opcional: dependerá se a extração do SBOM é feita aqui
  });

  Future<bool> existsAnalysis(String packageName, String version);

  Future<bool> isSecure(String packageName, String version);

  Future<String> ensureProjectExists(
    String projectType,
    String name,
    String version,
  );
}
