import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixArtist {
  String package;
  dynamic id;
  String? title;
  String? pic;
  String? desc;

  MixArtist({
    required this.package,
    required this.id,
    required this.title,
    this.desc,
    this.pic,
  });
}
