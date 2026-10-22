import 'music_resource.dart';
import 'song.dart';

class MusicCollection extends MusicResource {
  List<Song> songs;
  int? total;
  bool? hasMore;

  MusicCollection({
    required super.pluginId,
    required super.id,
    super.title,
    super.subtitle,
    super.cover,
    super.description,
    super.favorited,
    super.locallyFavorited,
    super.details,
    this.songs = const [],
    this.total,
    this.hasMore,
  });

  MusicCollection.fromJson(super.json)
    : songs = [
        for (final item in json['songs'] as List? ?? [])
          Song.fromJson({...item as Map, 'pluginId': json['pluginId']}),
      ],
      total = (json['total'] as num?)?.toInt(),
      hasMore = json['hasMore'] as bool?,
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'songs': songs.map((song) => song.toJson()).toList(),
    if (total != null) 'total': total,
    if (hasMore != null) 'hasMore': hasMore,
  };
}
