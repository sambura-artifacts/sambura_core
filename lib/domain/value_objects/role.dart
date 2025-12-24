import 'package:sambura_core/domain/exceptions/domain_exception.dart';

class Role {
  final String value;

  static const String admin = 'admin';
  static const String developer = 'developer';
  static const String viewer = 'viewer';

  static const List<String> _allowedRoles = [admin, developer, viewer];

  Role(String val) : value = val.trim().toLowerCase() {
    _validate(value);
  }

  void _validate(String val) {
    if (!_allowedRoles.contains(val)) {
      throw RoleException(
        'Perfil inválido. Valores permitidos: ${_allowedRoles.join(", ")}',
      );
    }
  }

  bool get isAdmin => value == admin;
  bool get isDeveloper => value == developer;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Role && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
