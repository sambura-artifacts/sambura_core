class ApplicationException implements Exception {
  final String message;
  final dynamic details;
  ApplicationException({required this.message, this.details});
}

class ApiKeyNotFoundException extends ApplicationException {
  ApiKeyNotFoundException(String apiKey)
    : super(message: 'API Key "$apiKey" não encontrado.');
}

class ListApiKeyNotFoundException extends ApplicationException {
  ListApiKeyNotFoundException()
    : super(message: 'Nenhuma API Key foi encontrada.');
}

class AccountNotFoundException extends ApplicationException {
  AccountNotFoundException(String externalId)
    : super(message: 'Seu usuário não foi encontrado.');
}

class AccountNotPermissionException extends ApplicationException {
  AccountNotPermissionException(String externalId)
    : super(message: 'Seu usuário não tem permissão para realizar a ação.');
}

class ExternalResourceNotFoundException extends ApplicationException {
  ExternalResourceNotFoundException(String resource, {super.details})
    : super(
        message:
            'O recurso "$resource" não foi encontrado no registro externo.',
      );
}

class ExternalServiceUnavailableException extends ApplicationException {
  ExternalServiceUnavailableException(String service, {super.details})
    : super(
        message:
            'O serviço externo "$service" está temporariamente indisponível.',
      );
}

class ExternalRegistryAuthException extends ApplicationException {
  ExternalRegistryAuthException({super.details})
    : super(message: 'Falha na autenticação com o registro externo.');
}

class InsecureArtifactException extends ApplicationException {
  InsecureArtifactException(String packageId, String version, {super.details})
    : super(
        message:
            'O artefato $packageId@$version falhou na análise de segurança.',
      );
}
