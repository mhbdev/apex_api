import 'package:timezone/timezone.dart' as tz;

class JsonChecker {
  static String? optString(Map<String, dynamic>? data, String key,
      {String? defValue = ''}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      return data[key] != null
          ? (data[key] != null ? data[key].toString() : defValue)
          : defValue;
    }
    return defValue;
  }

  static RegExp? optRegex(Map<String, dynamic>? data, String key,
      {RegExp? defValue}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      return data[key] != null
          ? (data[key] != null ? RegExp(data[key].toString()) : defValue)
          : defValue;
    }
    return defValue;
  }

  static int optInt(Map<String, dynamic>? data, String key,
      {int defValue = 0}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      return data[key] != null
          ? int.tryParse(data[key].toString()) ?? defValue
          : defValue;
    }
    return defValue;
  }

  static Uri? optUri(Map<String, dynamic>? data, String key, {Uri? defValue}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      return Uri.tryParse(data[key].toString()) ?? defValue;
    }
    return defValue;
  }

  static num optNum(Map<String, dynamic>? data, String key,
      {num defValue = 0}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      return data[key] != null
          ? num.tryParse(data[key].toString()) ?? defValue
          : defValue;
    }
    return defValue;
  }

  static double optDouble(Map<String, dynamic>? data, String key,
      {double defValue = 0.0}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      return data[key] != null
          ? double.tryParse(data[key].toString()) ?? defValue
          : defValue;
    }
    return defValue;
  }

  static DateTime? optDate(Map<String, dynamic>? data, String key,
      {DateTime? defValue}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      if (data[key] == null) {
        return defValue;
      }

      return (DateTime.tryParse(data[key].toString() +
                  tz.getLocation('Asia/Tehran').currentTimeZone.abbreviation) ??
              (defValue ?? DateTime.now()))
          .toLocal();
    }
    return defValue;
  }

  static bool optBool(Map<String, dynamic>? data, String key,
      {bool defValue = false}) {
    if (data == null) return defValue;
    if (data.containsKey(key)) {
      if (data[key] == 'YES' || data[key] == 1 || data[key] == true) {
        return true;
      } else if (data[key] == 'NO' || data[key] == 0 || data[key] == false) {
        return false;
      }

      return defValue;
    }
    return defValue;
  }
}