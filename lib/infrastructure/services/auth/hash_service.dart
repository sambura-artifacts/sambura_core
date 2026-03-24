// lib/infrastructure/services/auth/hash_service.dart
import 'package:bcrypt/bcrypt.dart';

class HashService {
  final String _pepper;

  HashService(this._pepper);

  String hashPassword(String password) {
    final passwordWithPepper = password + _pepper;

    return BCrypt.hashpw(passwordWithPepper, BCrypt.gensalt());
  }

  bool verify(String password, String hashed) {
    final passwordWithPepper = password + _pepper;
    return BCrypt.checkpw(passwordWithPepper, hashed);
  }
}
