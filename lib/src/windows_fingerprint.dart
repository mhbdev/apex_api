import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fingerprintjs/fingerprintjs.dart';
import 'package:flutter/foundation.dart';

class Fingerprint {
  static Future<String> getHash() async {
    final uid = _getId();

    return sha256.convert(utf8.encode(uid ?? '')).toString();
  }

  static Future<List<FingerprintComponent>> get() async {
    final uid = _getId();

    return [
      FC(sha256.convert(utf8.encode(uid ?? '')).toString()),
    ];
  }

  static _getId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String? uid;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      uid = (await deviceInfoPlugin.windowsInfo).deviceId;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      uid = (await deviceInfoPlugin.androidInfo).fingerprint;
      if (uid.isEmpty || uid == 'null') {
        uid = (await deviceInfoPlugin.androidInfo).id;
        if (uid.isEmpty || uid == 'null') {
          uid = (await deviceInfoPlugin.androidInfo).serialNumber;
        }
      }
    }
    return uid;
  }
}

class FC extends FingerprintComponent {
  final String deviceId;

  FC(this.deviceId);

  @override
  String get key => 'device_id';

  @override
  get value async => deviceId;
}
