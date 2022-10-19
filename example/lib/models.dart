import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';

class GetCurrenciesRequest extends Request {
  GetCurrenciesRequest() : super(1, isPublic: true);

  @override
  Future<Json> get json async => {};
}

class GetCurrenciesResponse extends Response {
  final List<Currency> currencies;

  GetCurrenciesResponse(this.currencies, {required Json data}) : super(data);

  factory GetCurrenciesResponse.fromJson(Json json) {
    final currencies = (json['currencies'] as List).map((e) => Currency.fromJson(e)).toList();
    return GetCurrenciesResponse(currencies, data: json);
  }
}

class CurrencyEntity extends Equatable {
  // For All Currencies
  final String symbol;
  final String name;
  final Color color;
  final int fraction;
  final String iconUrl;
  final bool canBuy;
  final bool canDeposit;
  final bool canWithdraw;
  final bool canSell;

  final bool isFiat;
  final bool isBase;

  // Only for Base Coins
  final num takerFee;
  final num makerFee;

  // Only for Fiat
  final num fee;

  // For Base Coins & Fiat
  final num minimumConvert;
  final num maximumConvert;

  final bool isUnknown;

  const CurrencyEntity(
      this.symbol,
      this.name,
      this.color,
      this.fraction,
      this.iconUrl, {
        this.isFiat = false,
        this.isBase = false,
        this.takerFee = 0,
        this.makerFee = 0,
        this.minimumConvert = 0,
        this.maximumConvert = 0,
        this.fee = 0,
        this.canBuy = false,
        this.canDeposit = false,
        this.canWithdraw = false,
        this.canSell = false,
        this.isUnknown = false,
      });

  factory CurrencyEntity.unknown() {
    return const CurrencyEntity('symbol', 'name', Colors.red, 0, 'iconUrl',
        isUnknown: true);
  }

  @override
  List<Object> get props => [
    symbol,
  ];
}


class Currency extends CurrencyEntity {
  const Currency(
      super.symbol,
      super.name,
      super.color,
      super.fraction,
      super.iconUrl, {
        super.canWithdraw,
        super.canSell,
        super.canBuy,
        super.canDeposit,
        super.fee,
        super.isBase,
        super.isFiat,
        super.makerFee,
        super.maximumConvert,
        super.minimumConvert,
        super.takerFee,
      });

  factory Currency.fromJson(Json json) {
    final properties = json['properties'];
    return Currency(
      JsonChecker.optString(json, 'symbol')!,
      JsonChecker.optString(json, 'name')!,
      Colors.red,
      JsonChecker.optInt(json, 'fraction', defValue: 2),
      JsonChecker.optString(json, 'icon')!,
      isFiat: JsonChecker.optString(json, 'is_fiat', defValue: 'NO') == 'YES',
      isBase: JsonChecker.optString(json, 'is_base', defValue: 'NO') == 'YES',
      takerFee: JsonChecker.optNum(properties, 'takers_fee'),
      makerFee: JsonChecker.optNum(properties, 'makers_fee'),
      minimumConvert: JsonChecker.optNum(properties, 'min_convert'),
      maximumConvert: JsonChecker.optNum(properties, 'max_convert'),
      fee: JsonChecker.optNum(properties, 'fee'),
      canSell: JsonChecker.optBool(json, 'can_sell'),
      canBuy: JsonChecker.optBool(json, 'can_buy'),
      canDeposit: JsonChecker.optBool(json, 'can_deposit'),
      canWithdraw: JsonChecker.optBool(json, 'can_withdraw'),
    );
  }

  Json toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'color': color.value.toRadixString(16),
      'fraction': fraction,
      'icon': iconUrl,
      'is_fiat': isFiat ? 'YES' : 'NO',
      'is_base': isBase ? 'YES' : 'NO',
      'takers_fee': takerFee,
      'makers_fee': makerFee,
      'fee': fee,
      'max_convert': maximumConvert,
      'min_convert': minimumConvert,
      'can_sell': canSell,
      'can_buy': canBuy,
      'can_withdraw': canWithdraw,
      'can_deposit': canDeposit,
    };
  }
}
