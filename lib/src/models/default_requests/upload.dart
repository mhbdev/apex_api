import 'package:apex_api/apex_api.dart';

class UploadResponse extends DataModel {
  final String? name;

  UploadResponse(this.name);

  factory UploadResponse.fromJson(Json json) {
    return UploadResponse(json.optString('name'));
  }
}
