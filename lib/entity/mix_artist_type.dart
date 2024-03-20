import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_song.dart';

@jsonSerializable
class MixArtistType {
  String site;
  dynamic id;
  String? name;

  List<MixArtistType>? subType = const [];

  MixArtistType({
    required this.site,
    this.id,
    this.name,
    this.subType = const [],
  });
}
