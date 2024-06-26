import 'package:audio_service/audio_service.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_album.dart';
import 'mix_artist.dart';
import 'mix_url.dart';

@jsonSerializable
class MixSong {
  String site;
  dynamic id;
  String? title;
  dynamic subTitle;
  List<MixArtist>? artist = const [];
  MixAlbum? album;
  String? url;
  List<MixUrl>? urls;
  String? pic;
  String? lyric;
  int? vip;
  dynamic listenCount;

  MixSong({
    required this.site,
    required this.id,
    required this.title,
    this.subTitle,
    this.artist = const [],
    this.album,
    this.url,
    this.urls,
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
      artUri: Uri.parse(pic ?? ""),
    );
  }
}
