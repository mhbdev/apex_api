import '../../../apex_api.dart';

class City {
  final String id;
  final String name;

  City(this.id, this.name);

  factory City.fromJson(Json json) {
    return City(
      JsonChecker.optString(json, 'id', defValue: '-1')!,
      JsonChecker.optString(json, 'name', defValue: 'Unknown')!,
    );
  }

  @override
  String toString() {
    return {
      'id': id,
      'name': name,
    }.toString();
  }
}

class Province {
  final String id;
  final String name;
  final List<City> cities;

  Province(this.id, this.name, this.cities);

  factory Province.fromJson(Json json) {
    return Province(
      JsonChecker.optString(json, 'id', defValue: '-1')!,
      JsonChecker.optString(json, 'name', defValue: 'Unknown')!,
      JsonChecker.optList<City>(
        json,
        'cities',
        defValue: [],
        reviver: (e) => City.fromJson(e),
      )!,
    );
  }

  @override
  String toString() {
    return {'id': id, 'name': name, 'cities': cities.toString()}.toString();
  }
}

class FetchProvinces extends DataModel {
  final List<Province> provinces;

  FetchProvinces.fromJson(Map<String, dynamic> json)
      : provinces = JsonChecker.optList<Province>(
          json,
          'provinces',
          defValue: [],
          reviver: (e) => Province.fromJson(e),
        )!;
}
