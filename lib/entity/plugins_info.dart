import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class PluginsInfo {
  String? name;
  String? site;
  String? version;
  String? author;
  String? icon;
  String? webSite;
  String? path;
  List<String>? method;

  @override
  String toString() {
    return "{name:$name,site:$site,version:$version,author:$author,icon:$icon,webSite:$webSite,path:$path,method:$method}";
  }
}
