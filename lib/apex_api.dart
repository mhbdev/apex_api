library apex_api;

import 'package:apex_api/src/preferences/database.dart';

import 'src/preferences/storage_util.dart';
import 'src/typedefs.dart';
import 'package:fingerprintjs/fingerprintjs.dart';

export 'src/clients/clients.dart';
export 'src/server.dart';
export 'src/server_widget.dart';
export 'src/models/connection_config.dart';
export 'src/models/request.dart';
export 'src/models/response.dart';
export 'src/cipher/models/key_pair.dart';
export 'src/notifier/change_notifier_builder.dart';
export 'src/notifier/multi_change_notifier_builder.dart';
export 'src/notifier/message_notifier.dart';
export 'src/notifier/message_notifier_builder.dart';
export 'src/utils/json_checker.dart';
export 'src/utils/mixins.dart';
export 'src/socket_join_controller.dart';
export 'src/socket_stream.dart';
export 'src/clients/connector.dart';
export 'src/typedefs.dart';
export 'src/models/default_requests/login.dart';
export 'src/preferences/database.dart';
export 'src/extensions/context_extensions.dart';
export 'src/extensions/map_extensions.dart';
export 'package:socket_io_client/socket_io_client.dart';
export 'package:equatable/equatable.dart';

/// Initialize Api
class ApexApi {
  static void init({
    StringCallback? fingerprintCallback,
    StringCallback? imeiCallback,
    StringCallback? imsiCallback,
  }) {
    StorageUtil.getInstance();

    if (imeiCallback != null) imeiCallback().then(ApexApiDb.setImei);
    if (imsiCallback != null) imsiCallback().then(ApexApiDb.setImsi);

    if (fingerprintCallback != null) {
      fingerprintCallback().then(ApexApiDb.setFingerprint);
    } else {
      // provide my own fingerprint
      if (!ApexApiDb.hasFingerprint) {
        Fingerprint.getHash().then(
          (value) => ApexApiDb.setFingerprint(value),
        );
      }
    }
  }
}
