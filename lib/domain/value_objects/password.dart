import 'package:sambura_core/domain/exceptions/domain_exception.dart';

class Password {
  final String value;

  Password(this.value) {
    _validate(value);
  }

  void _validate(String val) {
    // 1. Tamanho Mínimo (Segurança contra força bruta)
    if (val.length < 8) {
      throw PasswordException('A senha deve ter pelo menos 8 caracteres.');
    }

    // 2. Tamanho Máximo (Prevenção de ataques DoS por hashing pesado)
    if (val.length > 72) {
      throw PasswordException('A senha é muito longa.');
    }

    // 3. Complexidade (Entropia)
    final hasUppercase = val.contains(RegExp(r'[A-Z]'));
    final hasLowercase = val.contains(RegExp(r'[a-z]'));
    final hasDigits = val.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = val.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
      throw PasswordException(
        'A senha deve conter letras maiúsculas, minúsculas, números e caracteres especiais.',
      );
    }
  }

  @override
  String toString() => '********'; // Segurança: nunca logue a senha real
}
