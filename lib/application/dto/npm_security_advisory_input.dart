class NpmSecurityAdvisoryInput {
  final String advisoryId;
  final String moduleName;
  final String vulnerableVersions;
  final String patchedVersions;
  final String overview;
  final String recommendation;
  final String severity;

  NpmSecurityAdvisoryInput({
    required this.advisoryId,
    required this.moduleName,
    required this.vulnerableVersions,
    required this.patchedVersions,
    required this.overview,
    required this.recommendation,
    required this.severity,
  });
}
