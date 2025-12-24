import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:uuid/v7.dart';
import 'package:uuid/validation.dart';

class ExternalId {
  final String value;

  ExternalId(this.value) {
    _validate(value);
  }

  static ExternalId generate() {
    return ExternalId(UuidV7().generate());
  }

  void _validate(String value) {
    if (!UuidValidation.isValidUUID(fromString: value)) {
      throw ExternalIdInvalidException(value);
    }
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
