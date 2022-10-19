import 'package:apex_api/src/preferences/storage_util.dart';

class ApexApiDb {
  static String tokenKey = 'apex_api_token';
  static String fingerprintKey = 'apex_api_fingerprint';
  static String imeiKey = 'apex_api_imei';
  static String imsiKey = 'apex_api_imsi';

  static bool get isAuthenticated => StorageUtil.getString(tokenKey) != null;

  static bool get hasFingerprint =>
      StorageUtil.getString(fingerprintKey) != null;

  static bool get hasImei => StorageUtil.getString(imeiKey) != null;

  static bool get hasImsi => StorageUtil.getString(imsiKey) != null;

  static void setToken(String token) => StorageUtil.putString(tokenKey, token);

  static void removeToken() => StorageUtil.putString(tokenKey, null);

  static String? getToken() => StorageUtil.getString(tokenKey, defValue: null);

  static void setFingerprint(String fingerprint) =>
      StorageUtil.putString(fingerprintKey, fingerprint);

  static void removeFingerprint() => StorageUtil.putString(fingerprintKey, null);

  static String? getFingerprint() =>
      StorageUtil.getString(fingerprintKey, defValue: null);

  static void setImei(String imei) =>
      StorageUtil.putString(imeiKey, imei);

  static void removeImei() => StorageUtil.putString(imeiKey, null);

  static String? getImei() =>
      StorageUtil.getString(imeiKey, defValue: null);

  static void setImsi(String imsi) =>
      StorageUtil.putString(imsiKey, imsi);

  static void removeImsi() => StorageUtil.putString(imsiKey, null);

  static String? getImsi() =>
      StorageUtil.getString(imsiKey, defValue: null);
}
