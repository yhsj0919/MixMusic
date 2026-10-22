import 'music_collection.dart';

class Artist extends MusicCollection {
  Artist({
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
  Artist.fromJson(super.json) : super.fromJson();
}
