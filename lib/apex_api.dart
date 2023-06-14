library apex_api;

import 'dart:convert';
import 'dart:io';

import 'package:apex_api/src/preferences/database.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fingerprintjs/fingerprintjs.dart'
    if (dart.library.io) 'package:apex_api/src/unimplemented_fingerprint.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import 'src/preferences/storage_util.dart';
import 'src/typedefs.dart';

export 'package:equatable/equatable.dart';
export 'package:socket_io_client/socket_io_client.dart';

export 'src/api_wrapper.dart';
export 'src/clients/clients.dart';
export 'src/clients/connector.dart';
// export 'src/cipher/aes.dart';
// export 'src/cipher/crypto.dart';
// export 'src/cipher/models/key_pair.dart';
// export 'src/cipher/rsa.dart';
export 'src/clients/http/http_alt.dart';
export 'src/exceptions/exceptions.dart';
export 'src/extensions/context_extensions.dart';
export 'src/extensions/map_extensions.dart';
export 'src/models/connection_config.dart';
export 'src/models/default_requests/city_province.dart';
export 'src/models/default_requests/login.dart';
export 'src/models/reactive_widget_options.dart';
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
    /// The domain name that the token cookie should be saved under that name
    String? cookieDomainName,

    /// these will be called to set imei, imsi, fingerprint for each platform
    StringCallback? androidFingerprint,
    StringCallback? webFingerprint,
    StringCallback? iosFingerprint,
    StringCallback? windowsFingerprint,
    StringCallback? imeiCallback,
    StringCallback? imsiCallback,
    bool askPhonePermission = true,
  }) async {
    StorageUtil.getInstance();

    cookieDomain = cookieDomainName ?? '';

    if (imeiCallback != null) imeiCallback().then(ApexApiDb.setImei);
    if (imsiCallback != null) imsiCallback().then(ApexApiDb.setImsi);

    if (kIsWeb) {
      if (webFingerprint != null) {
        final value = await webFingerprint();
        ApexApiDb.setFingerprint(value);
      } else {
        // provide my own fingerprint using fingerprintjs2
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
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      if (androidFingerprint != null) {
        final value = await androidFingerprint();
        ApexApiDb.setFingerprint(value);
      } else {
        void createAndSetAndroidId() async {
          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          final fingerprint = androidInfo.version.sdkInt.toString() +
              androidInfo.version.release +
              androidInfo.version.securityPatch.toString() +
              androidInfo.manufacturer +
              androidInfo.hardware +
              androidInfo.model +
              androidInfo.id +
              androidInfo.board +
              androidInfo.bootloader +
              androidInfo.brand +
              androidInfo.device +
              androidInfo.displayMetrics.toMap().toString() +
              androidInfo.fingerprint +
              androidInfo.host;
          final fp = md5.convert(utf8.encode(fingerprint)).toString();

          Json additional = {
            'manufacturer': androidInfo.manufacturer,
            'release': androidInfo.version.release,
            'model': androidInfo.model,
            'brand': androidInfo.brand,
            'isPhysicalDevice': androidInfo.isPhysicalDevice,
          };
          ApexApiDb.setAdditional(additional);
          ApexApiDb.setFingerprint(fp);
        }

        if (askPhonePermission) {
          Map<Permission, PermissionStatus> permissionStatus = await [
            Permission.phone,
          ].request();

          if (permissionStatus.values.every((ps) => ps.isGranted)) {
            createAndSetAndroidId();
          } else {
            Fluttertoast.showToast(
              msg: 'Grant all permissions!',
              gravity: ToastGravity.BOTTOM,
            );
            exit(0);
          }
        } else {
          createAndSetAndroidId();
        }
      }
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      if (windowsFingerprint != null) {
        final value = await windowsFingerprint();
        ApexApiDb.setFingerprint(value);
      } else {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;

        final windowsId = windowsInfo.deviceId;
        final fp = md5.convert(utf8.encode(windowsId)).toString();
        ApexApiDb.setFingerprint(fp);
      }
    }
  }
}
