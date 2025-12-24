import 'dart:io';
import 'package:equatable/equatable.dart';

// Definindo o Environment (Dev, Staging, Prod)
enum Environment { development, staging, production }

/// Classe Imutável que armazena todas as configurações
/// de infraestrutura e variáveis de ambiente.
class EnvConfig extends Equatable {
  // ----------------------------------
  // 1. GERAL
  // ----------------------------------
  final Environment environment;
  final String appName;
  final int port;

  // ----------------------------------
  // 2. CONEXÃO DATABASE (Postgres)
  // ----------------------------------
  final String dbHost;
  final int dbPort;
  final String dbUser;
  final String dbPassword;
  final String dbName;

  // ----------------------------------
  // 3. CONEXÃO CACHE & QUEUE (Redis & RabbitMQ)
  // ----------------------------------
  final String redisHost;
  final int redisPort;
  final String rabbitmqHost;
  final int rabbitmqPort;
  final String rabbitmqUser;
  final String rabbitmqPass;

  // ----------------------------------
  // 4. CONEXÃO STORAGE (MinIO)
  // ----------------------------------
  final String siloHost;
  final int siloPort;
  final String siloAccessKey;
  final String siloSecretKey;
  final bool siloUseSSL;
  final String bucketName;

  // ----------------------------------
  // 5. KEYCLOAK (AUTH/OIDC)
  // ----------------------------------
  final String keycloakUrl;
  final String keycloakRealm;
  final String keycloakClientId;
  String get keycloakJwksUrl =>
      '$keycloakUrl/realms/$keycloakRealm/protocol/openid-connect/certs';

  // ----------------------------------
  // 6. HASHICORP VAULT (SEGREDOS)
  // ----------------------------------
  final String vaultUrl;
  final String vaultToken;
  final String vaultSecretPath;

  const EnvConfig({
    required this.environment,
    this.appName = 'Sambura Core',
    required this.port,
    required this.dbHost,
    required this.dbPort,
    required this.dbUser,
    required this.dbPassword,
    required this.dbName,
    required this.redisHost,
    required this.redisPort,
    required this.rabbitmqHost,
    required this.rabbitmqPort,
    required this.rabbitmqUser,
    required this.rabbitmqPass,
    required this.siloHost,
    required this.siloPort,
    required this.siloAccessKey,
    required this.siloSecretKey,
    required this.siloUseSSL,
    required this.bucketName,
    required this.keycloakUrl,
    required this.keycloakRealm,
    required this.keycloakClientId,
    required this.vaultUrl,
    required this.vaultToken,
    required this.vaultSecretPath,
  });

  @override
  List<Object?> get props => [
    environment,
    port,
    dbHost,
    dbName,
    redisHost,
    rabbitmqHost,
    siloHost,
    bucketName,
    keycloakUrl,
    keycloakRealm,
    vaultUrl,
  ];
}

/// CLASSE PARA CARREGAR AS VARIÁVEIS DE AMBIENTE
///
/// O objetivo desta classe é ler as variáveis do sistema (ambiente)
/// e montar a classe de configuração imutável [EnvConfig].
class Env {
  EnvConfig load() {
    String getString(String key, {String defaultValue = ''}) {
      final value = Platform.environment[key];
      if (value == null || value.isEmpty) {
        if (defaultValue.isEmpty) {
          throw Exception('Missing required environment variable: $key');
        }
        return defaultValue;
      }
      return value;
    }

    int getInt(String key, {int defaultValue = 0}) {
      try {
        return int.parse(getString(key));
      } catch (e) {
        return defaultValue;
      }
    }

    return EnvConfig(
      // GERAL
      environment: Environment.development,
      port: getInt('PORT', defaultValue: 8080),

      // DATABASE (POSTGRES)
      dbHost: getString('DB_HOST', defaultValue: 'localhost'),
      dbPort: getInt('DB_PORT', defaultValue: 5432),
      dbUser: getString('DB_USER', defaultValue: 'sambura'),
      dbPassword: getString('DB_PASSWORD', defaultValue: 'sambura_db_secret'),
      dbName: getString('DB_NAME', defaultValue: 'sambura_metadata'),

      // CACHE & QUEUE
      redisHost: getString('REDIS_HOST', defaultValue: 'sambura_cache'),
      redisPort: getInt('REDIS_PORT', defaultValue: 6379),
      rabbitmqHost: getString('RABBITMQ_HOST', defaultValue: 'sambura_broker'),
      rabbitmqPort: getInt('RABBITMQ_PORT', defaultValue: 5672),
      rabbitmqUser: getString('RABBITMQ_USER', defaultValue: ''),
      rabbitmqPass: getString('RABBITMQ_PASS', defaultValue: ''),

      // STORAGE (MINIO)
      siloHost: getString('SILO_HOST', defaultValue: 'sambura_silo_infra'),
      siloPort: getInt('SILO_PORT', defaultValue: 9000),
      siloAccessKey: getString(
        'SILO_ACCESS_KEY',
        defaultValue: 'sambura_admin',
      ),
      siloSecretKey: getString(
        'SILO_SECRET_KEY',
        defaultValue: 'sambura_silo_secret',
      ),
      bucketName: getString('BUCKET_NAME', defaultValue: 'sambura-blobs'),
      siloUseSSL: bool.fromEnvironment('SILO_USESSL', defaultValue: false),

      // KEYCLOAK
      keycloakUrl: getString(
        'KEYCLOAK_URL',
        defaultValue: 'http://keycloak_host:8080',
      ),
      keycloakRealm: getString('KEYCLOAK_REALM', defaultValue: 'sambura'),
      keycloakClientId: getString(
        'KEYCLOAK_CLIENT_ID',
        defaultValue: 'sambura-core-client',
      ),

      // HASHICORP VAULT
      vaultUrl: getString('VAULT_URL', defaultValue: 'http://localhost:8200'),
      vaultToken: getString('VAULT_TOKEN', defaultValue: 'root_token_sambura'),
      vaultSecretPath: getString(
        'VAULT_SECRET_PATH',
        defaultValue: 'secret/data/sambura/dev',
      ),
    );
  }
}
