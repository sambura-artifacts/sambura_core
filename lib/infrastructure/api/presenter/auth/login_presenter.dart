import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Centraliza a formatação de respostas para o processo de autenticação (Login).
class LoginPresenter {
  /// Formata a resposta de sucesso, retornando o token JWT e dados básicos do usuário.
  static Response success(String token, String username) {
    final payload = {
      'token': token,
      'username': username,
      'type': 'Bearer',
      'expires_in': 3600, // Valor referencial baseado na config do Vault
      'timestamp': DateTime.now().toIso8601String(),
    };

    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Retorna uma resposta de acesso negado quando as credenciais são inválidas.
  static Response unauthorized() {
    return Response.forbidden(
      jsonEncode({
        'error': 'Credenciais inválidas.',
        'message': 'O nome de usuário ou a senha informados estão incorretos.',
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Trata falhas sistêmicas durante o processo de login.
  static Response error(dynamic exception) {
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Falha na autenticação.',
        'message': 'Ocorreu um erro interno ao processar sua solicitação.',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}
