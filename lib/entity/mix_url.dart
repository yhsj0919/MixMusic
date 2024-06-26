import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixUrl {
  String site;
  String? name;
  dynamic quality;
  String? prefix;
  String? suffix;
  int? size;
  String? mid;
  String? url;

  MixUrl({
    required this.site,
    this.name,
    this.quality,
    this.prefix,
    this.suffix,
    this.size,
    this.mid,
    this.url,
  });
}
