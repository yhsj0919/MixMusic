import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixAlbumType {
  String package;
  dynamic id;
  String? name;

  List<MixAlbumType>? subType = const [];

  MixAlbumType({
    required this.package,
    required this.id,
    required this.name,
    this.subType = const [],
  });
}
