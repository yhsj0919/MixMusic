import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixPlaylistType {
  String package;
  dynamic id;
  String? name;

  List<MixPlaylistType>? subType = const [];

  MixPlaylistType({
    required this.package,
    required this.id,
    required this.name,
    this.subType = const [],
  });
}
