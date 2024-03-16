import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_song.dart';

@jsonSerializable
class MixPlaylistType {
  String site;
  dynamic id;
  String? name;

  List<MixPlaylistType>? subType = const [];

  MixPlaylistType({
    required this.site,
    required this.id,
    required this.name,
    this.subType = const [],
  });
}
