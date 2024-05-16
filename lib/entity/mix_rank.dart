import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_song.dart';

@jsonSerializable
class MixRank {
  String site;
  dynamic id;

  String? title;

  String? pic;
  String? subTitle;
  String? desc;
  dynamic songCount;
  List<MixSong>? songs = const [];

  MixRank({
    required this.site,
    required this.id,
    required this.title,
    required this.pic,
    this.subTitle,
    this.desc,
    this.songCount,
    this.songs = const [],
  });
}
