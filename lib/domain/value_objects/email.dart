import 'package:sambura_core/domain/exceptions/domain_exception.dart';

class Email {
  final String value;

  Email(String val) : value = val.trim().toLowerCase() {
    _validate(value);
  }

  void _validate(String val) {
    if (val.isEmpty) {
      throw EmailException('O email não pode estar vazio.');
    }

    if (val.length > 255) {
      throw EmailException('O email é demasiado longo.');
    }

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );

    if (!emailRegex.hasMatch(val)) {
      throw EmailException('O formato do email é inválido.');
    }
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Email && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
