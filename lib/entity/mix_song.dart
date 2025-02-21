import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:mix_music/entity/mix_mv.dart';

import 'mix_album.dart';
import 'mix_artist.dart';
import 'mix_quality.dart';

@jsonSerializable
class MixSong {
  String package;
  dynamic id;
  String? title;
  dynamic subTitle;
  List<MixArtist>? artist = const [];
  MixAlbum? album;
  String? url;
  List<MixQuality>? quality;
  String? pic;
  String? lyric;
  int? vip;
  dynamic listenCount;
  bool? match;
  MixSong? matchSong;
  MixMv? mv;
  int? playQuality;

  MixSong({
    required this.package,
    required this.id,
    required this.title,
    this.subTitle,
    this.artist = const [],
    this.album,
    this.mv,
    this.url,
    this.quality,
    this.playQuality,
    required this.pic,
    this.lyric,
    this.listenCount,
    this.vip,
  });

  String? getUrl() {
    return match != true ? url : matchSong?.url;
  }

  String? getLyric() {
    return match != true ? lyric : matchSong?.lyric;
  }

  MediaItem mediaItem() {
    return MediaItem(
        id: (match != true ? url : matchSong?.url) ?? "",
        album: album?.title,
        title: title ?? "",
        artist: artist?.isNotEmpty == true ? artist?.first.title : "未知",
        duration: const Duration(milliseconds: 10),
        artUri: Uri.parse(pic ?? ""),
        extras: {"id": md5.convert(utf8.encode("$package$id")).toString()});
  }
}
