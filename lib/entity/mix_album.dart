import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_artist.dart';
import 'mix_song.dart';
@jsonSerializable
class MixAlbum {
  String site;
  dynamic id;
  String? title;
  String? pic;
  String? subTitle;
  String? desc;
  String? publishDate;
  dynamic songCount;
  List<MixArtist>? artist = const [];
  List<MixSong>? songs = const [];

  MixAlbum({
    required this.site,
    required this.id,
    required this.title,
    required this.pic,
    this.subTitle,
    this.desc,
    this.songCount,
    this.publishDate,
    this.artist = const [],
    this.songs = const [],
  });
}
