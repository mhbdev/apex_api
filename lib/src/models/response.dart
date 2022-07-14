import 'package:apex_api/src/preferences/database.dart';

import '../exceptions.dart';
import '../utils/json_checker.dart';

abstract class ResponseModel {
  final int success;
  final String? message;
  Map<String, dynamic>? data;
  final ConnectionError? error;
  final String? errorMessage;

  bool get hasData => data != null;

  bool get hasError => error != null;

  ResponseModel.fromJson({
    this.success = -1,
    this.message,
    this.data,
    this.error,
    this.errorMessage,
  });
}

class Response extends ResponseModel {
  final bool playSound;

  Response(Map<String, dynamic>? data, {super.error, super.errorMessage})
      : playSound = data != null && data.containsKey('play_sound')
            ? (data['play_sound'] == 1)
            : false,
        super.fromJson(data: data) {
    if (data != null && data.containsKey('is_logged_in')) {
      if (data['is_logged_in'] == 0) {
        Database.removeToken();
        // TODO : clear database notify user
      }
    }

    if (data != null && data.containsKey('token') && data['token'] != null) {
      Database.setToken(data['token']);
    }

    if (message != null) {
      // TODO : show message anyway
      // DialogUtil.showNotification(
      //     success == 1 ? NotificationType.success : NotificationType.error,
      //     message ?? '');
    }
  }

  factory Response.fromJson(Map<String, dynamic>? json) {
    if (json != null) return Response(json);

    return Response({
      'success': -1,
      'message':
          'Contact our Tech support @ApexTeamSupport and Ask for help.\nError code : 0x00000000'
    });
  }

  @override
  String toString() {
    return data.toString();
  }
}
