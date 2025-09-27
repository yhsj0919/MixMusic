import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixLrc {
  String package;
  dynamic id;
  String? lrc;

  MixLrc({required this.package, required this.id, required this.lrc});
}
