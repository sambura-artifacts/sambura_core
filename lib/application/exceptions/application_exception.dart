class ApplicationException implements Exception {
  final String message;
  ApplicationException(this.message);
}

class ApiKeyNotFoundException extends ApplicationException {
  ApiKeyNotFoundException(String apiKey)
    : super('API Key "$apiKey" não encontrado.');
}

class ListApiKeyNotFoundException extends ApplicationException {
  ListApiKeyNotFoundException() : super('Nenhuma API Key foi encontrada.');
}

class AccountNotFoundException extends ApplicationException {
  AccountNotFoundException(String externalId)
    : super('Seu usuário não foi encontrado.');
}

class AccountNotPermissionException extends ApplicationException {
  AccountNotPermissionException(String externalId)
    : super('Seu usuário não tem permissão para realizar a ação.');
}
