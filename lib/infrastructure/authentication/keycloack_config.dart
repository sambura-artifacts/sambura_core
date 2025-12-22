import 'dart:io';

class KeycloakConfig {
  final String serverUrl;
  final String realm;
  final String clientId;
  final String? clientSecret; // Opcional se for client público

  KeycloakConfig({
    required this.serverUrl,
    required this.realm,
    required this.clientId,
    this.clientSecret,
  });

  /// Factory pra carregar as paradas direto do ambiente (Docker/Environment)
  factory KeycloakConfig.fromEnv() {
    return KeycloakConfig(
      serverUrl:
          Platform.environment['KC_SERVER_URL'] ?? 'http://localhost:8080',
      realm: Platform.environment['KC_REALM'] ?? 'sambura',
      clientId: Platform.environment['KC_CLIENT_ID'] ?? 'sambura-backend',
      clientSecret: Platform.environment['KC_CLIENT_SECRET'],
    );
  }

  /// Gera a URL do endpoint de discovery (OpenID Connect)
  String get discoveryUrl =>
      '$serverUrl/realms/$realm/.well-known/openid-configuration';

  /// URL pra validar o token (Introspection)
  String get introspectionEndpoint =>
      '$serverUrl/realms/$realm/protocol/openid-connect/token/introspect';

  /// URL pra pegar a chave pública (JWKS) e validar o JWT sem bater no server toda hora
  String get jwksUri =>
      '$serverUrl/realms/$realm/protocol/openid-connect/certs';
}
