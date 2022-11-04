import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fingerprintjs/fingerprintjs.dart';
import 'package:platform_device_id/platform_device_id.dart';

class Fingerprint {
  static Future<String> getHash() async {
    return sha256
        .convert(utf8.encode(await PlatformDeviceId.getDeviceId ?? ''))
        .toString();
  }

  static Future<List<FingerprintComponent>> get() async {
    return [
      FC(sha256
          .convert(utf8.encode(await PlatformDeviceId.getDeviceId ?? ''))
          .toString()),
    ];
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
