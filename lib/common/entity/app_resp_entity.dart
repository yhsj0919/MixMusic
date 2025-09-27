import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'page_entity.dart';

class AppRespEntity<T> {
  int? code;
  String? msg;
  PageEntity? page;
  T? data;

  AppRespEntity(this.code, this.msg, this.data, {this.page});

  AppRespEntity.fromJson(json) {
    if (json['code'] != null) {
      code = json['code']?.toInt();
    }
    if (json['msg'] != null) {
      msg = json['msg']?.toString();
    }
    if (json["page"] != null) {
      page = PageEntity.fromJson(json['page']);
    }

    if (json["data"] != null) {
      data = _generateOBJ<T>(json['data']);
    }
  }

  bool isSuccess() => code == 200;

  String info() => msg ?? "操作失败";

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> resp = <String, dynamic>{};
    resp['code'] = code;
    resp['msg'] = msg;
    if (data is String) {
      resp['data'] = data;
    } else if (data is Map<dynamic, dynamic>) {
      resp['data'] = data;
    } else {
      resp['data'] = json.decode(JsonMapper.serialize(data));
    }
    return resp;
  }

  @override
  String toString() {
    final Map<String, dynamic> map =  <String, dynamic>{};
    map['code'] = code;
    map['msg'] = msg;
    map['data'] = data.toString();

    return map.toString();
  }

  T? _generateOBJ<T>(mJson) {
    if (T is String) {
      return mJson.toString() as T?;
    } else if (T is Map<dynamic, dynamic>) {
      return mJson as T?;
    } else {
      /// List类型数据由fromJsonAsT判断处理
      return JsonMapper.deserialize(json.encode(mJson));
    }
  }
}
