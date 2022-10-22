import 'package:apex_api/apex_api.dart';

extension JsonExtension on Json {
  String? optString(String key, {String? defaultValue}) {
    return JsonChecker.optString(this, key, defValue: defaultValue);
  }

  DateTime? optDateTime(String key, {DateTime? defaultValue}) {
    return JsonChecker.optDate(this, key, defValue: defaultValue);
  }

  bool? optBool(String key, {bool? defaultValue}) {
    return JsonChecker.optBool(this, key, defValue: defaultValue);
  }

  num optNum(String key, {num defaultValue = 0.0}) {
    return JsonChecker.optNum(this, key, defValue: defaultValue);
  }

  int optInt(String key, {int defaultValue = 0}) {
    return JsonChecker.optInt(this, key, defValue: defaultValue);
  }

  double optDouble(String key, {double defaultValue = 0.0}) {
    return JsonChecker.optDouble(this, key, defValue: defaultValue);
  }
}
