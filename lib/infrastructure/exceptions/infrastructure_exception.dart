class InfrastructureException implements Exception {
  final String message;
  InfrastructureException(this.message);
}

class ControllerException extends InfrastructureException {
  @override
  ControllerException(super.message);
}
