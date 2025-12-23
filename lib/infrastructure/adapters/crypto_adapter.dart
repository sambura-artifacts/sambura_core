import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/hash_port.dart';

/// Adapter para operações de hash e criptografia implementando IHashPort.
/// 
/// Segue o padrão Hexagonal Architecture (Ports & Adapters).
class CryptoAdapter implements IHashPort {
  final String _pepper;
  final Logger _log = LoggerConfig.getLogger('CryptoAdapter');
  
  // Configurações do Argon2 (simulado com PBKDF2 por enquanto)
  static const int _iterations = 10000;
  static const int _keyLength = 32;

  CryptoAdapter({required String pepper}) : _pepper = pepper;

  @override
  String hashPassword(String password) {
    try {
      // Adiciona pepper para aumentar segurança
      final passwordWithPepper = password + _pepper;
      
      // Gera salt aleatório
      final salt = generateRandomBytes(16);
      final saltHex = hex.encode(salt);
      
      // Hash com PBKDF2
      final hash = _pbkdf2(passwordWithPepper, salt);
      final hashHex = hex.encode(hash);
      
      // Formato: $pbkdf2$iterations$salt$hash
      final result = '\$pbkdf2\$$_iterations\$$saltHex\$$hashHex';
      
      _log.fine('✅ Password hashed successfully');
      return result;
    } catch (e, stack) {
      _log.severe('❌ Failed to hash password: $e', e, stack);
      rethrow;
    }
  }

  @override
  bool verifyPassword(String password, String hash) {
    try {
      // Parse hash components
      final parts = hash.split('\$');
      if (parts.length != 5 || parts[1] != 'pbkdf2') {
        _log.warning('⚠️  Invalid hash format');
        return false;
      }
      
      final iterations = int.parse(parts[2]);
      final salt = hex.decode(parts[3]);
      final storedHash = parts[4];
      
      // Hash password with same salt
      final passwordWithPepper = password + _pepper;
      final computedHash = _pbkdf2(passwordWithPepper, salt, iterations: iterations);
      final computedHashHex = hex.encode(computedHash);
      
      final matches = computedHashHex == storedHash;
      
      _log.fine(matches ? '✅ Password verified' : '⚠️  Password mismatch');
      return matches;
    } catch (e, stack) {
      _log.severe('❌ Failed to verify password: $e', e, stack);
      return false;
    }
  }

  @override
  String sha256Hash(List<int> data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  @override
  List<int> generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  @override
  String generateRandomString(int length) {
    final bytes = generateRandomBytes(length);
    return base64Url.encode(bytes).replaceAll('=', '').substring(0, length);
  }

  /// PBKDF2 implementation
  List<int> _pbkdf2(
    String password,
    List<int> salt, {
    int iterations = _iterations,
    int keyLength = _keyLength,
  }) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockCount = (keyLength / 32).ceil();
    final derivedKey = <int>[];

    for (var i = 1; i <= blockCount; i++) {
      var block = <int>[];
      var u = hmac.convert([...salt, ...[(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff]]).bytes;
      block = u;

      for (var j = 1; j < iterations; j++) {
        u = hmac.convert(u).bytes;
        block = _xor(block, u);
      }

      derivedKey.addAll(block);
    }

    return derivedKey.sublist(0, keyLength);
  }

  List<int> _xor(List<int> a, List<int> b) {
    final result = <int>[];
    for (var i = 0; i < a.length; i++) {
      result.add(a[i] ^ b[i]);
    }
    return result;
  }
}
