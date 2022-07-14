library apex_api;

import 'package:apex_api/src/preferences/database.dart';

import 'src/preferences/storage_util.dart';
import 'src/typedefs.dart';
import 'package:fingerprintjs/fingerprintjs.dart';

/// Initialize Api
class ApexApi {
  static void init({FingerprintCallback? fingerprintCallback}) {
    StorageUtil.getInstance();
    if (fingerprintCallback != null) {
      fingerprintCallback().then((fingerprint) {
        Database.setFingerprint(fingerprint);
      });
    } else {
      // provide my own fingerprint
      if (!Database.hasFingerprint) {
        Fingerprint.getHash().then((value) => Database.setFingerprint(value));
      }
    }
  }
}
