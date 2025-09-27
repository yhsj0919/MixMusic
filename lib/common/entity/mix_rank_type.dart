import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'mix_rank.dart';

@jsonSerializable
class MixRankType {
  String package;
  dynamic id;
  String? title;

  List<MixRank>? rankList = const [];

  MixRankType({
    required this.package,
    required this.id,
    required this.title,
    this.rankList = const [],
  });
}
