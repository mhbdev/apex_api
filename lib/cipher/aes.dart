import 'dart:convert';

import 'package:encrypt/encrypt.dart';

class AESAlgorithm {
  /// The AES init vector generated randomly with length of 16
  final IV _iv = IV.fromSecureRandom(16);

  late Encrypter _aes;

  IV get initVector {
    return _iv;
  }

  AESAlgorithm(secretKey) {
    _aes = Encrypter(
      AES(
        Key.fromBase64(
          secretKey,
        ),
        mode: AESMode.cbc,
      ),
    );
  }

  /// Encrypts [plainText] with AES algorithm
  ///
  /// Returns encrypted [String] encoded to [base64]
  String encrypt(String plainText) {
    return _aes.encrypt(plainText, iv: _iv).base64;
  }

  ///Decrypts [encryptedText] with AES algorithm
  ///
  /// Returns decrypted [String]
  String decrypt(String encryptedText) {
    return utf8.decode(base64Decode(
        _aes.decrypt(Encrypted.fromBase64(encryptedText), iv: _iv)));
  }
}
