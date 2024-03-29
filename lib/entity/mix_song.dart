

import 'package:audio_service/audio_service.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_album.dart';
import 'mix_artist.dart';
@jsonSerializable
class MixSong {
  String site;
  dynamic id;
  dynamic mid;
  String? contentId;
  String? mediaId;
  dynamic albumAudioId;
  String? title;
  dynamic subTitle;
  List<MixArtist>? artist = const [];
  MixAlbum? album;
  String? url;
  String? pic;
  String? lyric;
  int? vip;
  dynamic listenCount;

  MixSong({
    required this.site,
    required this.id,
    this.mid,
    this.contentId,
    this.mediaId,
    this.albumAudioId,
    required this.title,
    this.subTitle,
    this.artist = const [],
    this.album,
    this.url,
    required this.pic,
    this.lyric,
    this.listenCount,
    this.vip,
  });

  MediaItem mediaItem() {
    return MediaItem(
      id: url ?? "",
      album: album?.title,
      title: title ?? "",
      artist: artist?.isNotEmpty == true ? artist?.first.name : "未知",
      duration: const Duration(milliseconds: 10),
      artUri: Uri.parse(pic??""),
    );
  }
}
