class MusicResource {
  String pluginId;
  dynamic id;
  String title;
  String? subtitle;
  String? cover;
  String? description;
  bool? favorited;
  bool? locallyFavorited;
  Map<String, dynamic> details;

  MusicResource({
    required this.pluginId,
    required this.id,
    this.title = '',
    this.subtitle,
    this.cover,
    this.description,
    this.favorited,
    this.locallyFavorited,
    this.details = const {},
  });

  MusicResource.fromJson(Map json)
    : pluginId = json['pluginId'],
      id = json['id'],
      title = json['title'] as String? ?? '',
      subtitle = json['subTitle']?.toString(),
      cover = json['pic'] as String?,
      description = (json['description'] ?? json['desc']) as String?,
      favorited = json['favorited'] as bool?,
      locallyFavorited = json['locallyFavorited'] as bool?,
      details = Map<String, dynamic>.from(json);

  Map<String, dynamic> toJson() => {
    ...details,
    'pluginId': pluginId,
    'id': id,
    'title': title,
    'subTitle': subtitle,
    'pic': cover,
    'favorited': favorited,
    'locallyFavorited': locallyFavorited,
    if (description != null) 'description': description,
  };
}
