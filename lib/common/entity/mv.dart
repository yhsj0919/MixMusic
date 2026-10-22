import 'music_resource.dart';
import 'quality.dart';

class Mv extends MusicResource {
  String? url;
  List<Quality> qualities;

  Mv({
    required super.pluginId,
    required super.id,
    super.title,
    super.subtitle,
    super.cover,
    super.description,
    super.favorited,
    super.locallyFavorited,
    super.details,
    this.url,
    this.qualities = const [],
  });
  Mv.fromJson(super.json)
    : url = json['url'] as String?,
      qualities = [
        for (final item in json['quality'] as List? ?? [])
          Quality.fromJson({
            'pluginId': json['pluginId'],
            'id': json['id'],
            ...item as Map,
          }),
      ],
      super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'url': url,
    'quality': qualities.map((quality) => quality.toJson()).toList(),
  };
}
