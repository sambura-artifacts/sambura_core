class PackagePathParser {
  static String extractName(String path) {
    // 1. Remove o prefixo se houver o separador de tarball /-/
    String base = path.contains('/-/') ? path.split('/-/').first : path;

    // 2. Se termina com .tgz, removemos a parte da versão (-1.2.3.tgz)
    if (base.endsWith('.tgz')) {
      final versionRegex = RegExp(r'-(\d+\.\d+\.\d+.*)\.tgz$');
      return base.replaceFirst(versionRegex, '');
    }

    return base;
  }

  static String extractVersion(String path) {
    // Regex mais robusta para pegar a versão antes do .tgz
    final regex = RegExp(r'-(\d+\.\d+\.\d+[^/]*)\.tgz$');
    final match = regex.firstMatch(path);

    return match?.group(1) ?? '0.0.0';
  }
}
