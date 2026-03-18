import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:mix_music/common/entity/mix_mv.dart';
import 'package:mix_music/common/entity/mix_song.dart';

import 'mix_quality.dart';

@jsonSerializable
class MixDownload {
  String package;
  dynamic id;
  String? title;
  String? pic;
  String? artist;
  String? album;
  String? url;
  MixQuality? quality;
  String? filePath;
  int? status;

  MixDownload({
    required this.package,
    required this.id,
    this.title,
    this.pic,
    this.quality,
    this.artist,
    this.album,
    this.url,
  });

  static MixDownload fromSong(MixSong song, MixQuality? quality) {
    return MixDownload(
      package: song.package,
      id: song.id,
      title: song.title,
      pic: song.pic,
      artist: song.artist?.map((e) => e.title).join("、") ?? "",
      album: song.album?.title,
      quality: quality,
    );
  }

  static MixDownload fromMv(MixMv mv, MixQuality? quality) {
    return MixDownload(
      package: mv.package,
      id: mv.id,
      title: mv.title,
      pic: mv.pic,
      artist: mv.artist?.map((e) => e.title).join("、") ?? "",
      album: null,
      quality: quality,
    );
  }
}
