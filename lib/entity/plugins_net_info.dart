import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class PluginsNetInfo {
  String? name;
  String? package;
  String? url;
  String? version;
  int? minAppCode;
}
