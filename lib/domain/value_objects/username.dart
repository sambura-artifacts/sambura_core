import 'package:sambura_core/domain/exceptions/domain_exception.dart';

class Username {
  final String value;

  Username(this.value) {
    _validate(value);
  }

  void _validate(String val) {
    if (val.trim().isEmpty) {
      throw UsernameException('Username não pode ser vazio.');
    }

    if (val.length < 3 || val.length > 30) {
      throw UsernameException('Username deve ter entre 3 e 30 caracteres.');
    }

    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!regex.hasMatch(val)) {
      throw UsernameException(
        'Username contém caracteres inválidos. Use apenas letras, números, _ ou -.',
      );
    }
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Username && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
