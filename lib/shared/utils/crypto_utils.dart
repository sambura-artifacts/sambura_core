import 'dart:math';
import 'dart:convert';

class CryptoUtils {
  static final Random _random = Random.secure();

  static String generateSecureKey([int length = 32]) {
    final values = List<int>.generate(length, (i) => _random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '').substring(0, length);
  }

  static String generateSalt([int length = 16]) {
    final values = List<int>.generate(length, (i) => _random.nextInt(256));
    return base64.encode(values);
  }
}
