import 'quality.dart';

class Song {
  bool get vip => details['vip'] == true || details['vip'] == 1;

  String pluginId;
  dynamic id;
  String title;
  String? cover;
  String? subtitle;
  String? url;
  List<Quality> qualities;
  int? playQuality;
  bool? favorited;
  bool? locallyFavorited;
  Map<String, dynamic> details;
  Song? matchedSong;
  Song get actualSong => matchedSong ?? this;

  Song({
    required this.pluginId,
    required this.id,
    required this.title,
    this.cover,
    this.subtitle,
    this.url,
    this.qualities = const [],
    this.playQuality,
    this.favorited,
    this.locallyFavorited,
    this.details = const {},
    this.matchedSong,
  });

  factory Song.fromJson(Map json) => Song(
    pluginId: json['pluginId'],
    id: json['id'],
    title: json['title'],
    cover: json['pic'],
    subtitle: json['subTitle']?.toString(),
    url: json['url'],
    qualities: (json['quality'] as List? ?? [])
        .map(
          (item) =>
              Quality.fromJson({...item as Map, 'pluginId': json['pluginId']}),
        )
        .toList(),
    playQuality: json['playQuality'],
    favorited: json['favorited'] as bool?,
    locallyFavorited: json['locallyFavorited'] as bool?,
    details: Map<String, dynamic>.from(json),
    matchedSong: json['matchedSong'] is Map
        ? Song.fromJson(json['matchedSong'] as Map)
        : null,
  );

  Map<String, dynamic> toJson() => {
    ...details,
    'pluginId': pluginId,
    'id': id,
    'title': title,
    'pic': cover,
    'subTitle': subtitle,
    'url': url,
    'quality': qualities.map((item) => item.toJson()).toList(),
    'playQuality': playQuality,
    'favorited': favorited,
    'locallyFavorited': locallyFavorited,
    'matchedSong': matchedSong?.toJson(),
  };
}
