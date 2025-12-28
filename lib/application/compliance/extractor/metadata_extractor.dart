abstract class MetadataExtractor {
  bool canHandle(String filename);
  Future<String?> extractPackageMetadata(List<int> bytes);
  String getPurlNamespace(String name);
}
