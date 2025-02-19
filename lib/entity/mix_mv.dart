import 'package:audio_service/audio_service.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_album.dart';
import 'mix_artist.dart';
import 'mix_quality.dart';

@jsonSerializable
class MixMv {
  String package;
  dynamic id;
  String? title;
  dynamic subTitle;
  List<MixArtist>? artist = const [];
  String? url;
  List<MixQuality>? quality;
  String? pic;
  String? desc;

  dynamic listenCount;

  MixMv({
    required this.package,
    required this.id,
    required this.title,
    this.quality,
    this.subTitle,
    this.artist = const [],
    this.url,
    this.pic,
    this.desc,
  });
}
