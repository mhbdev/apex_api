import '../../../apex_api.dart';

class Country extends Equatable {
  final String symbol;
  final String name;
  final String? flag;

  const Country(this.symbol, this.name, {this.flag});

  factory Country.fromJson(Json json) {
    return Country(
      JsonChecker.optString(json, 'symbol', defValue: '-1')!,
      JsonChecker.optString(json, 'name', defValue: 'Unknown')!,
      flag: JsonChecker.optString(json, 'flag'),
    );
  }

  Json toJson() {
    return {
      'symbol': symbol,
      'name': name,
    };
  }

  @override
  String toString() {
    return {
      'symbol': symbol,
      'name': name,
    }.toString();
  }

  @override
  List<Object?> get props => [symbol];
}

class City extends Equatable {
  final String id;
  final String name;

  const City(this.id, this.name);

  factory City.fromJson(Json json) {
    return City(
      JsonChecker.optString(json, 'id', defValue: '-1')!,
      JsonChecker.optString(json, 'name', defValue: 'Unknown')!,
    );
  }

  Json toJson() {
    return {'id': id, 'name': 'name'};
  }

  @override
  String toString() {
    return {
      'id': id,
      'name': name,
    }.toString();
  }

  @override
  List<Object?> get props => [id];
}

class Province extends Equatable {
  final String id;
  final String name;
  final List<City> cities;

  const Province(this.id, this.name, this.cities);

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

  Json toJson() {
    return {
      'id': id,
      'name': name,
      'cities': cities.map((e) => e.toJson()),
    };
  }

  @override
  String toString() {
    return {'id': id, 'name': name, 'cities': cities.toString()}.toString();
  }

  @override
  List<Object?> get props => [id];
}

class FetchProvinces extends DataModel {
  final List<Province> provinces;

  FetchProvinces.fromJson(Json json)
      : provinces = JsonChecker.optList<Province>(
          json,
          'provinces',
          defValue: [],
          reviver: (e) => Province.fromJson(e),
        )!;
}

class FetchCountries extends DataModel {
  final List<Country> countries;

  FetchCountries.fromJson(Json json)
      : countries = JsonChecker.optList<Country>(
          json,
          'countries',
          defValue: [],
          reviver: (e) => Country.fromJson(e),
        )!;
}
