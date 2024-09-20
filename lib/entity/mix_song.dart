import 'package:audio_service/audio_service.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

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

  MixSong({
    required this.package,
    required this.id,
    required this.title,
    this.subTitle,
    this.artist = const [],
    this.album,
    this.url,
    this.quality,
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
      artist: artist?.isNotEmpty == true ? artist?.first.title : "未知",
      duration: const Duration(milliseconds: 10),
      artUri: Uri.parse(pic ?? ""),
    );
  }
}
