import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixAlbumType {
  String site;
  dynamic id;
  String? name;

  List<MixAlbumType>? subType = const [];

  MixAlbumType({
    required this.site,
    required this.id,
    required this.name,
    this.subType = const [],
  });
}
