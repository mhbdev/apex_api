import 'package:apex_api/src/typedefs.dart';
import 'package:flutter/foundation.dart';

import '../preferences/storage_util.dart';

enum Method {
  post,
  get
}

abstract class Request {
  final String? handlerUrl;
  final String? groupName;
  final bool isPublic;
  final bool needCredentials;
  final int action;
  final bool? encrypt;

  Request(
    this.action, {
    this.encrypt,
    this.groupName,
    this.handlerUrl,
    this.isPublic = false,
    this.needCredentials = false,
    this.method = Method.post,
  });

  Future<Map<String, dynamic>> get json;

  /// Defines The request method which can be [Method.POST] or [Method.GET]
  Method method;

  Future<bool> has(String key) async {
    return (await json).containsKey(key);
  }

  /// This adds an entry with [key] and [value] into [_params] map
  void addParam({required String key, required dynamic value}) async {
    (await json)[key] = value;
  }

  /// This add a map [values] into [_params] map
  void addParams(Map<String, dynamic> values) async {
    (await json).addAll(values);
  }

  /// Removes a param with [key] key from [_params]
  void removeParam({required String key}) async {
    (await json).remove(key);
  }

  /// Clears [_params] map
  void clearParams() async {
    (await json).clear();
  }

  /// Convert params map to query for using in requests with [Method.GET] method
  ///
  /// Returns query format of [_params] something like this `?firstKey=firstValue&secondKey=secondValue`
  Future<String> params2Query() async {
    String q = "?";
    (await json).forEach((key, value) {
      q += "$key=$value&";
    });
    return q;
  }

  @nonVirtual
  Future<Json> toJson() async {
    Json finalResult;
    finalResult = {
      'action': action,
      if (groupName != null && isPublic) 'group_name': groupName,
    }..addAll(await json);

    final token = StorageUtil.getString('apex_api_token');
    if (!finalResult.containsKey('token')) {
      if (token != null) finalResult.addAll({'token': token});
    } else {
      if (token != null) finalResult['token'] = token;
    }

    return finalResult;
  }
}

class SimpleRequest extends Request {
  final Map<String, dynamic>? data;

  SimpleRequest(int action, {bool isPublic = false, this.data})
      : super(action, isPublic: isPublic);

  @override
  Future<Map<String, dynamic>> get json async => data ?? {};
}

class JoinGroupRequest extends Request {
  final Map<String, dynamic>? data;

  JoinGroupRequest(String groupName, {this.data})
      : super(2, isPublic: true, groupName: groupName);

  @override
  Future<Map<String, dynamic>> get json async => data ?? {};
}
