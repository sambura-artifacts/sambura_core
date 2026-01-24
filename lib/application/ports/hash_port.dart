/// Port (Interface) para serviço de hash e criptografia.
///
/// Define o contrato para operações criptográficas.
abstract class HashPort {
  /// Gera hash de uma senha com salt e pepper.
  ///
  /// [password] - Senha em texto plano
  /// Returns: Hash da senha
  String hashPassword(String password);

  /// Verifica se uma senha corresponde ao hash.
  ///
  /// [password] - Senha em texto plano
  /// [hash] - Hash armazenado
  /// Returns: true se corresponde
  bool verifyPassword(String password, String hash);

  /// Gera um hash SHA-256 de dados arbitrários.
  ///
  /// [data] - Dados a serem hasheados
  /// Returns: Hash hexadecimal
  String sha256Hash(List<int> data);

  /// Gera bytes aleatórios criptograficamente seguros.
  ///
  /// [length] - Número de bytes
  /// Returns: Lista de bytes aleatórios
  List<int> generateRandomBytes(int length);

  /// Gera uma string aleatória em base64url.
  ///
  /// [length] - Comprimento desejado
  /// Returns: String aleatória
  String generateRandomString(int length);
}
