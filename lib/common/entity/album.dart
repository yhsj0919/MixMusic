import 'music_collection.dart';

class Album extends MusicCollection {
  Album({
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
  });
  Album.fromJson(super.json) : super.fromJson();
}
