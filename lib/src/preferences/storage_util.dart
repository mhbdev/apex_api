import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../typedefs.dart';

class StorageUtil {
  static StorageUtil? _storageUtil;
  static SharedPreferences? _preferences;

  static Future<StorageUtil?> getInstance() async {
    if (_storageUtil == null) {
      // keep local instance till it is fully initialized.
      var secureStorage = StorageUtil._();
      await secureStorage._init();
      _storageUtil = secureStorage;
    }
    return _storageUtil;
  }

  StorageUtil._();

  Future<SharedPreferences?> _init() async {
    _preferences = await SharedPreferences.getInstance();
    return _preferences;
  }

  // get string
  static String? getString(String key, {String? defValue}) {
    if (_preferences == null) return defValue;
    return _preferences!.getString(key) ?? defValue;
  }

  // put string
  static Future<bool>? putString(String key, String? value) {
    if (_preferences == null) return null;
    if (value == null) {
      _preferences!.remove(key);
      return Future.value(true);
    }
    return _preferences!.setString(key, value);
  }

  // get bool
  static bool? getBool(String key, {bool? defValue}) {
    if (_preferences == null) return defValue;
    return _preferences!.getBool(key) ?? defValue;
  }

  // put bool
  static Future<bool>? putBool(String key, bool? value) {
    if (_preferences == null) return null;
    if (value == null) {
      _preferences!.remove(key);
      return Future.value(true);
    }
    return _preferences!.setBool(key, value);
  }

  // get int
  static int? getInt(String key, {int? defValue}) {
    if (_preferences == null) return defValue;
    return _preferences!.getInt(key) ?? defValue;
  }

  // put int
  static Future<bool>? putInt(String key, int? value) {
    if (_preferences == null) return null;
    if (value == null) {
      _preferences!.remove(key);
      return Future.value(true);
    }
    return _preferences!.setInt(key, value);
  }

  // get double
  static double? getDouble(String key, {double? defValue}) {
    if (_preferences == null) return defValue;
    return _preferences!.getDouble(key) ?? defValue;
  }

  // put double
  static Future<bool>? putDouble(String key, double? value) {
    if (_preferences == null) return null;
    if (value == null) {
      _preferences!.remove(key);
      return Future.value(true);
    }
    return _preferences!.setDouble(key, value);
  }

  // put json
  static Future<bool>? putJson(String key, Json? value) {
    if (_preferences == null) return null;
    if (value == null) {
      _preferences!.remove(key);
      return Future.value(true);
    }
    return _preferences!.setString(key, jsonEncode(value));
  }

  // get string
  static Json? getJson(String key, {Json? defValue}) {
    if (_preferences == null) return defValue;
    try {
      return jsonDecode(_preferences!.getString(key) ?? '{}');
    } on FormatException {
      return defValue;
    }
  }
}
