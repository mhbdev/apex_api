import 'dart:convert';

import 'aes.dart';
import 'rsa.dart';

class Crypto {
  late AESAlgorithm _aes;
  late RSAAlgorithm _rsa;

  Crypto(String secretKey, String publicKey) {
    _aes = AESAlgorithm(secretKey);
    _rsa = RSAAlgorithm(publicKey);
  }

  /// Encrypts [message] in my way (combines [_aes] and [_rsa])
  ///
  /// Returns `RSAEncryptedIV:AESEncryptedMessage`
  String encrypt(String message) {
    return "${_rsa.encrypt(_aes.initVector.base64)}:${base64Encode(
          utf8.encode(
            _aes.encrypt(
              base64Encode(
                utf8.encode(
                  message,
                ),
              ),
            ),
          ),
        )}";
  }

  /// Decrypts [message] with AES algorithm
  ///
  /// Returns AES decrypted [String]
  String decrypt(String message) {
    return _aes.decrypt(message);
  }
}
