import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:sambura_core/application/ports/hash_port.dart';

class BcryptHashAdapter implements HashPort {
  final String _pepper;
  final Random _random = Random.secure();

  BcryptHashAdapter(this._pepper);

  @override
  String hashPassword(String password) {
    final passwordWithPepper = password + _pepper;
    return BCrypt.hashpw(passwordWithPepper, BCrypt.gensalt());
  }

  @override
  bool verifyPassword(String password, String hash) {
    final passwordWithPepper = password + _pepper;
    return BCrypt.checkpw(passwordWithPepper, hash);
  }

  @override
  String sha256Hash(List<int> data) {
    return sha256.convert(data).toString();
  }

  @override
  List<int> generateRandomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  @override
  String generateRandomString(int length) {
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (_) => charset[_random.nextInt(charset.length)],
    ).join();
  }
}
