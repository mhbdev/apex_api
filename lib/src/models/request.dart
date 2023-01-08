import 'package:apex_api/apex_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../preferences/storage_util.dart';

enum Method { post, get }

abstract class Request extends Equatable {
  final String? groupName;
  final bool isPublic;
  final bool needCredentials;
  final int action;
  final bool? encrypt;
  final bool isEmpty;

  Request(
    this.action, {
    this.isEmpty = false,
    this.encrypt,
    this.groupName,
    this.isPublic = false,
    this.needCredentials = false,
  });

  String? get handlerUrl => null;

  Future<String> get zip async => '{$action => $groupName => $isPublic => ${await toJson()}}';

  Future<Json> get json;

  Future<Json> get responseMock async => {};

  final Json _finalJson = {};

  /// Defines The request method which can be [Method.post] or [Method.get]
  Method get method => Method.post;

  Future<bool> has(String key) async {
    return _finalJson.containsKey(key);
  }

  /// This adds an entry with [key] and [value] into [_params] map
  void addParam({required String key, required dynamic value}) async {
    _finalJson[key] = value;
  }

  /// This add a map [values] into [_params] map
  void addParams(Json values) async {
    _finalJson.addAll(values);
  }

  bool containsKey(String key) {
    return _finalJson.containsKey(key);
  }

  /// Removes a param with [key] key from [_params]
  void removeParam({required String key}) async {
    _finalJson.remove(key);
  }

  /// Clears [_params] map
  void clearParams() async {
    _finalJson.clear();
  }

  /// Convert params map to query for using in requests with [Method.GET] method
  ///
  /// Returns query format of [_params] something like this `?firstKey=firstValue&secondKey=secondValue`
  Future<String> params2Query() async {
    String q = "?";
    _finalJson.forEach((key, value) {
      q += "$key=$value&";
    });
    return q;
  }

  @nonVirtual
  Future<Json> toJson() async {
    Json finalResult;
    finalResult = !isEmpty
        ? ({
            'action': action,
            if (groupName != null && isPublic) 'group_name': groupName,
          }
          ..addAll(await json)
          ..addAll(_finalJson))
        : {};

    if (!isEmpty && ![1001, 1002, 1003, 1004].contains(action)) {
      final token = StorageUtil.getString('apex_api_token');
      if (!finalResult.containsKey('token')) {
        if (token != null) finalResult.addAll({'token': token});
      } else {
        if (token != null) finalResult['token'] = token;
      }
    }

    return finalResult;
  }

  Future<BaseResponse<DM>> send<DM extends DataModel>(
    BuildContext context, {
    bool? showProgress,
    bool? showRetry,
    VoidCallback? onStart,
    OnSuccess<DM>? onSuccess,
    OnConnectionError? onError,
    bool ignoreExpireTime = false,
  }) {
    return context.api.request<DM>(this,
        showProgress: showProgress,
        showRetry: showRetry,
        onStart: onStart,
        onSuccess: onSuccess,
        onError: onError,
        ignoreExpireTime: ignoreExpireTime);
  }

  Future<BaseResponse> startUpload<DM extends DataModel>(
    BuildContext context, {
    bool? showProgress,
    // bool? showRetry,
    VoidCallback? onStart,
    OnSuccess<DM>? onSuccess,
    OnConnectionError? onError,
    bool ignoreExpireTime = false,
    ValueChanged<VoidCallback>? cancelToken,
    String? fileName,
    String fileKey = 'file',
    String? filePath,
    Uint8List? blobData,
    ValueChanged<double>? onProgress,
  }) {
    return context.api.uploadFile<DM>(
      this,
      // showRetry: showRetry,
      showProgress: showProgress,
      cancelToken: cancelToken,
      fileKey: fileKey,
      onProgress: onProgress,
      blobData: blobData,
      fileName: fileName,
      filePath: filePath,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  @override
  List<Object?> get props => [action, json];
}

class SimpleRequest extends Request {
  final Json? data;
  final Json? responseMockData;

  factory SimpleRequest.empty({bool? encrypt, Json? responseMockData}) => SimpleRequest(
        0,
        isEmpty: true,
        encrypt: encrypt,
        responseMockData: responseMockData,
      );

  SimpleRequest(
    int action, {
    this.data,
    this.responseMockData,
    bool isPublic = false,
    bool isEmpty = false,
    String? groupName,
    bool needCredentials = false,
    bool? encrypt,
  }) : super(
          action,
          groupName: groupName,
          isEmpty: isEmpty,
          needCredentials: needCredentials,
          isPublic: isPublic,
          encrypt: encrypt,
        );

  @override
  Future<Json> get json async => data ?? {};

  @override
  Future<Json> get responseMock async => responseMockData ?? {};
}

class JoinGroupRequest extends Request {
  final Json? data;

  JoinGroupRequest(String groupName, {this.data}) : super(2, isPublic: true, groupName: groupName);

  @override
  Future<Json> get json async => data ?? {};
}
