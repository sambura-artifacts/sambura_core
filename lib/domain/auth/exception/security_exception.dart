import 'package:sambura_core/domain/exceptions/exceptions.dart';

class SecurityException implements DomainException {
  @override
  final String message;
  SecurityException(this.message);
  @override
  String toString() => 'SecurityException: $message';
}
