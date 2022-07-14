import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class RSAAlgorithm {
  late Encrypter _rsa;

  RSAAlgorithm(String key) {
    final parser = RSAKeyParser();
    final RSAPublicKey publicKey = parser.parse(key) as RSAPublicKey;
    _rsa = Encrypter(
      RSA(
        publicKey: publicKey,
        encoding: RSAEncoding.OAEP,
      ),
    );
  }

  /// Encrypts [plainText] with RSA algorithm
  ///
  /// Returns encrypted [String] encoded to [base64]
  String encrypt(String plainText) {
    return _rsa.encrypt(plainText).base64;
  }

  ///Decrypts [encryptedText] with RSA algorithm
  ///
  /// Returns RSA decrypted [String]
  String decrypt(Encrypted encryptedText) {
    return _rsa.decrypt(encryptedText);
  }
}
