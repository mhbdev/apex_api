library apex_api;

import 'dart:convert';

import 'package:apex_api/src/preferences/database.dart';
import 'package:crypto/crypto.dart';
import 'package:fingerprintjs/fingerprintjs.dart'
    if (dart.library.io) 'package:apex_api/src/unimplemented_fingerprint.dart';

import 'src/preferences/storage_util.dart';
import 'src/typedefs.dart';

export 'package:equatable/equatable.dart';
export 'package:socket_io_client/socket_io_client.dart';

export 'src/cipher/models/key_pair.dart';
export 'src/clients/clients.dart';
export 'src/clients/connector.dart';
export 'src/exceptions/exceptions.dart';
export 'src/extensions/context_extensions.dart';
export 'src/extensions/map_extensions.dart';
export 'src/models/connection_config.dart';
export 'src/models/default_requests/login.dart';
export 'src/models/request.dart';
export 'src/models/response.dart';
export 'src/notifier/change_notifier_builder.dart';
export 'src/notifier/message_notifier.dart';
export 'src/notifier/message_notifier_builder.dart';
export 'src/notifier/multi_change_notifier_builder.dart';
export 'src/preferences/database.dart';
export 'src/server.dart';
export 'src/server_widget.dart';
export 'src/socket_join_controller.dart';
export 'src/socket_stream.dart';
export 'src/typedefs.dart';
export 'src/utils/json_checker.dart';
export 'src/utils/mixins.dart';
export 'src/widgets/login_builder.dart';
export 'src/widgets/reactive_widget.dart';

String cookieDomain = '';

/// Initialize Api
class ApexApi {
  static Future<void> init({
    String? cookieDomainName,

    /// these will be called to set imei, imsi, fingerprint
    StringCallback? fingerprintCallback,
    StringCallback? imeiCallback,
    StringCallback? imsiCallback,
  }) async {
    StorageUtil.getInstance();

    cookieDomain = cookieDomainName ?? '';

    if (imeiCallback != null) imeiCallback().then(ApexApiDb.setImei);
    if (imsiCallback != null) imsiCallback().then(ApexApiDb.setImsi);

    if (fingerprintCallback != null) {
      final value = await fingerprintCallback();
      ApexApiDb.setFingerprint(value);
    } else {
      // provide my own fingerprint
      if (!ApexApiDb.hasFingerprint) {
        final finger = (await Fingerprint.get());
        finger.removeWhere((e) => e.key == 'screenResolution');
        finger.removeWhere((e) => e.key == 'adBlock');
        final String fingerprint = md5
            .convert(utf8.encode(finger
                .map((e) => e.value.toString())
                .join('')
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(',', '')
                .replaceAll(' ', '')))
            .toString();

        ApexApiDb.setFingerprint(fingerprint.toString());
      }
    }
  }
}
