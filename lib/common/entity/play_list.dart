import 'music_collection.dart';

class PlayList extends MusicCollection {
  PlayList({
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
  PlayList.fromJson(super.json) : super.fromJson();
}
