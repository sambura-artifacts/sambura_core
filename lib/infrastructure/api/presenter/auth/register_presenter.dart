import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Responsável por formatar a saída da funcionalidade de Registro de Usuário.
/// Centraliza a lógica de mapeamento entre Exceções de Domínio e Respostas HTTP.
class RegisterPresenter {
  /// Formata a resposta de sucesso para a criação de conta.
  static Response success(String username) {
    final payload = {
      'message': 'Usuário $username criado com sucesso.',
      'status': 'created',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return Response(
      201, // Created
      body: jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Mapeia erros de domínio ou infraestrutura para o formato adequado ao cliente API.
  static Response error(dynamic exception) {
    String message = 'Ocorreu um erro inesperado no processamento do cadastro.';
    int statusCode = 500;

    // Mapeamento de exceções específicas do Domínio (Value Objects/Entities)
    if (exception.toString().contains('UsernameException')) {
      message = 'O nome de usuário fornecido é inválido ou já está em uso.';
      statusCode = 400;
    } else if (exception.toString().contains('EmailException')) {
      message = 'O endereço de e-mail fornecido não é válido.';
      statusCode = 400;
    } else if (exception is FormatException) {
      message = 'O formato do JSON enviado é inválido.';
      statusCode = 400;
    }

    final payload = {'error': message, 'code': statusCode};

    return Response(
      statusCode,
      body: jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  }
}
