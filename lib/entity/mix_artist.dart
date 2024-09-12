import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixArtist {
  String package;
  dynamic id;
  String? name;
  String? pic;
  String? desc;

  MixArtist({
    required this.package,
    required this.id,
    required this.name,
    this.desc,
    this.pic,
  });
}
