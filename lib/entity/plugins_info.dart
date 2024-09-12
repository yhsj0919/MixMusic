import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class PluginsInfo {
  String? name;
  String? site;
  String? package;
  String? version;
  int? versionCode;
  String? author;
  String? icon;
  String? webSite;
  String? updateUrl;
  String? path;
  String? code;
  String? desc;

  @override
  String toString() {
    return "{name:$name,site:$site,package:$package,version:$version,versionCode:$versionCode,author:$author,icon:$icon,webSite:$webSite,updateUrl:$updateUrl,path:$path,desc:$desc}";
  }
}
