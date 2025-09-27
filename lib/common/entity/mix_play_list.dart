
import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_song.dart';
@jsonSerializable
class MixPlaylist{
  String package;
  dynamic id;
  String? title;
  String? pic;
  String? subTitle;
  String? desc;
  dynamic listenCount;
  dynamic songCount;
  List<MixSong>? songs = const [];

  MixPlaylist({
    required this.package,
    required this.id,
    required this.title,
    required this.pic,
    this.subTitle,
    this.desc,
    this.listenCount,
    this.songCount,
    this.songs = const [],
  });
}