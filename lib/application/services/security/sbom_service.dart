import 'dart:convert';

class SbomService {
  String generateNpmSbom(Map<String, dynamic> packageJson) {
    return jsonEncode({
      "bomFormat": "CycloneDX",
      "specVersion": "1.4",
      "components": [
        {
          "name": packageJson['name'],
          "version": packageJson['version'],
          "type": "library",
          "purl": "pkg:npm/${packageJson['name']}@${packageJson['version']}",
        },
      ],
    });
  }
}
