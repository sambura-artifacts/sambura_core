class PackagePathParser {
  static String extractName(String path) {
    if (path.contains('/-/')) {
      return path.split('/-/').first;
    }
    return path.split('-').first;
  }

  static String extractVersion(String path) {
    final regex = RegExp(r'-(\d+\.\d+\.\d+[^/]*)\.tgz$');
    final match = regex.firstMatch(path);

    return match?.group(1) ?? '0.0.0';
  }
}
