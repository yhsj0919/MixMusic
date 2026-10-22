import 'music_collection.dart';

class Rank extends MusicCollection {
  List<Rank> ranks;
  bool get isGroup =>
      ranks.isNotEmpty ||
      details['ranks'] is List ||
      details['rankList'] is List;
  Rank({
    required super.pluginId,
    required super.id,
    super.title,
    super.subtitle,
    super.cover,
    super.description,
    super.favorited,
    super.locallyFavorited,
    super.details,
    super.songs,
    super.total,
    super.hasMore,
    this.ranks = const [],
  });
  Rank.fromJson(super.json)
    : ranks = [
        for (final item
            in json['ranks'] as List? ?? json['rankList'] as List? ?? [])
          Rank.fromJson({...item as Map, 'pluginId': json['pluginId']}),
      ],
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (ranks.isNotEmpty) 'ranks': ranks.map((rank) => rank.toJson()).toList(),
  };
}
