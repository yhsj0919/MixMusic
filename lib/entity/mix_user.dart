import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixUser {
  String package;
  dynamic id;
  String? name;
  String? pic;
  String? desc;
  int? login;
  int? vip;
  dynamic vipEndTime;

  MixUser({
    required this.package,
    this.id,
    this.name,
    this.desc,
    this.pic,
    this.login,
    this.vip,
    this.vipEndTime,
  });
}
