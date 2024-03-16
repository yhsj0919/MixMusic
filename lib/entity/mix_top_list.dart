import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_song.dart';
@jsonSerializable
class MixTopList {
  String site;
  dynamic id;
  dynamic groupName;
  dynamic groupId;
  String? title;

  String? pic;
  String? subTitle;
  String? desc;
  String? period;
  dynamic songCount;
  List<MixSong>? songs = const [];

  MixTopList({
    required this.site,
    required this.id,
    required this.title,
    required this.pic,
    this.subTitle,
    this.groupId,
    this.groupName,
    this.desc,
    this.period,
    this.songCount,
    this.songs = const [],
  });
}
