import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:mix_music/entity/mix_rank.dart';

import 'mix_song.dart';

@jsonSerializable
class MixRankType {
  String site;
  dynamic id;
  String? title;

  List<MixRank>? rankList = const [];

  MixRankType({
    required this.site,
    required this.id,
    required this.title,
    this.rankList = const [],
  });
}
