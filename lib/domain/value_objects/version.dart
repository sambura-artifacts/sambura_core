import 'package:equatable/equatable.dart';

/// Value Object representando uma versão semântica (SemVer).
/// Garante que a versão seja válida e imutável.
class Version extends Equatable implements Comparable<Version> {
  final String value;
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;

  const Version._({
    required this.value,
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
  });

  /// Cria uma Version validada seguindo SemVer.
  ///
  /// Exemplos válidos: "1.0.0", "2.3.4", "1.0.0-alpha", "1.0.0-beta.1"
  factory Version.create(String value) {
    if (value.isEmpty) {
      throw ArgumentError('Version cannot be empty');
    }

    // Regex SemVer básico
    final semverPattern = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9\-.]+))?$',
    );

    final match = semverPattern.firstMatch(value);
    if (match == null) {
      throw ArgumentError('Invalid semantic version: $value');
    }

    return Version._(
      value: value,
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      preRelease: match.group(4),
    );
  }

  /// Cria sem validação (para reconstrução do banco)
  factory Version.unsafe(String value) {
    try {
      return Version.create(value);
    } catch (_) {
      // Se falhar, retorna uma versão "relaxada"
      return Version._(value: value, major: 0, minor: 0, patch: 0);
    }
  }

  /// Verifica se é uma versão de pré-lançamento
  bool get isPreRelease => preRelease != null;

  /// Verifica se é uma versão estável (major >= 1 e sem pre-release)
  bool get isStable => major >= 1 && !isPreRelease;

  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Pre-release versions have lower precedence than normal versions
    if (isPreRelease && !other.isPreRelease) return -1;
    if (!isPreRelease && other.isPreRelease) return 1;

    // Compare pre-release strings lexicographically
    if (isPreRelease && other.isPreRelease) {
      return preRelease!.compareTo(other.preRelease!);
    }

    return 0;
  }

  bool operator >(Version other) => compareTo(other) > 0;
  bool operator <(Version other) => compareTo(other) < 0;
  bool operator >=(Version other) => compareTo(other) >= 0;
  bool operator <=(Version other) => compareTo(other) <= 0;

  @override
  String toString() => value;

  @override
  List<Object?> get props => [value];
}
