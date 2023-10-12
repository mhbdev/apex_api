import '../../apex_api.dart';

enum LoginStep { showUsername, showOtp, showPassword, showUpgrade, failure, success }

class BaseResponse<DM extends DataModel> {
  final int? success;
  final String? message;
  final ServerException? error;
  final String? errorMessage;
  final int expiresAt;
  final DM? model;

  Json? data;

  bool get isSuccessful => hasData && (success != null && success! >= 0);

  bool get isFailure => hasError || success == -1;

  bool get hasData => data != null;

  bool get hasError => error != null;

  LoginStep get loginStep {
    switch (success) {
      case -6:
        return LoginStep.showUpgrade;
      case -4:
        return LoginStep.showOtp;
      case -5:
        return LoginStep.showPassword;
      case -3:
        return LoginStep.showUsername;
      case -1:
        return LoginStep.failure;
      default:
        return LoginStep.success;
    }
  }

  BaseResponse({this.data, this.error, this.errorMessage, this.model})
      : success = JsonChecker.optInt(data, 'success'),
        message = JsonChecker.optString(data, 'message', defValue: null),
        expiresAt = DateTime.now().millisecondsSinceEpoch +
            Duration(seconds: JsonChecker.optInt(data, 'save_local_duration', defValue: 0)!)
                .inMilliseconds {
    if (data != null && data!.containsKey('is_logged_in')) {
      bool saveLocal = JsonChecker.optInt(data, 'save_local_duration', defValue: 0)! > 0;
      if (!saveLocal && data!['is_logged_in'] == 0) {
        ApexApiDb.removeToken();
        // TODO : clear database notify user
      }
    }

    if (data != null && data!.containsKey('token') && data!['token'] != null) {
      ApexApiDb.setToken(data!['token']);
    }
  }

  bool containsKey(String key) {
    if (data != null) {
      return data!.containsKey(key);
    }
    return false;
  }

  dynamic operator [](String key) {
    if (data == null) {
      return null;
    }
    return data![key];
  }

  @override
  String toString() {
    return {
      'hasData': hasData,
      'hasError': hasError,
      if (data != null) 'data': data,
      if (error != null) 'error': error,
      if (errorMessage != null) 'errorMessage': errorMessage,
    }.toString();
  }
}

class DataModel {
  DataModel();

  factory DataModel.fromJson(Json json) => DataModel();
}

// class Response extends BaseResponse {
//   final bool playSound;
//
//   Response(Map<String, dynamic>? data, {super.model, super.error, super.errorMessage})
//       : playSound = data != null && data.containsKey('play_sound')
//       ? (data['play_sound'] == 1)
//       : false,
//         super(data: data) {
//     if (data != null && data.containsKey('is_logged_in')) {
//       bool saveLocal = JsonChecker.optInt(data, 'save_local_duration',
//           defValue: 0)! > 0;
//       if (!saveLocal && data['is_logged_in'] == 0) {
//         ApexApiDb.removeToken();
//         // TODO : clear database notify user
//       }
//     }
//
//     if (data != null && data.containsKey('token') && data['token'] != null) {
//       ApexApiDb.setToken(data['token']);
//     }
//     //
//     // if (message != null) {
//     //   // TODO : show message anyway
//     //   // DialogUtil.showNotification(
//     //   //     success == 1 ? NotificationType.success : NotificationType.error,
//     //   //     message ?? '');
//     // }
//   }
//
//   factory Response.fromJson(Map<String, dynamic>? json, Map<Type, DataModel> responseModels) {
//     if (json != null) return Response(json, responseModels[Type]);
//
//     return Response({
//       'success': -1,
//       'message':
//       'Contact our Tech support @ApexTeamSupport and Ask for help.\nError code : 0x00000000'
//     });
//   }
//
//   @override
//   String toString() => data.toString();
// }
