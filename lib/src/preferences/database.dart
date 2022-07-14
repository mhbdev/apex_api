import 'package:apex_api/src/preferences/storage_util.dart';

class Database {
  static String tokenKey = 'apex_api_token';
  static String fingerprintKey = 'apex_api_fingerprint';

  static bool get isAuthenticated => StorageUtil.getString(tokenKey) != null;
  static bool get hasFingerprint => StorageUtil.getString(fingerprintKey) != null;

  static setToken(String token) {
    StorageUtil.putString(tokenKey, token);
  }

  static removeToken() {
    StorageUtil.putString(tokenKey, null);
  }

  static String? getToken() {
    return StorageUtil.getString(tokenKey, defValue: null);
  }

  static setFingerprint(String fingerprint) {
    StorageUtil.putString(fingerprintKey, fingerprint);
  }

  static removeFingerprint() {
    StorageUtil.putString(fingerprintKey, null);
  }

  static String? getFingerprint() {
    return StorageUtil.getString(fingerprintKey, defValue: null);
  }
}