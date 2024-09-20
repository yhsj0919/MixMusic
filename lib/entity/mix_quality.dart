import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixQuality {
  String package;
  String? title;
  dynamic id;
  dynamic quality;
  int? size;
  String? url;

  MixQuality({
    required this.package,
    this.title,
    this.quality,
    this.id,
    this.size,
    this.url,
  });
}
