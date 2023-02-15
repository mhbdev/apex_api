import 'package:apex_api/apex_api.dart';

class TestDataModel extends DataModel {
  final int id;

  TestDataModel._(this.id);

  factory TestDataModel.fromJson(Json json) {
    return TestDataModel._(json.optInt('id', defaultValue: 0)!);
  }
}
