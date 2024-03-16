import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixArtist {
  String site;
  dynamic id;
  String? name;
  String? pic;

  MixArtist({
    required this.site,
    required this.id,
    required this.name,
    this.pic,
  });
}
