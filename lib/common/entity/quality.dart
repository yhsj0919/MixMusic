class Quality {
  static const levels = {
    128: '标准',
    320: '高品质',
    1000: '无损',
    2000: 'Hi-Res',
    3000: '母带',
  };

  static int select(List<Quality> qualities, int preferred) {
    if (qualities.isEmpty) return preferred;
    final values = qualities.map((item) => item.value).toList()..sort();
    return values.lastWhere(
      (value) => value <= preferred,
      orElse: () => values.first,
    );
  }

  String pluginId;
  dynamic id;
  String title;
  int value;
  dynamic size;
  String? url;
  Map<String, dynamic> details;

  Quality({
    required this.pluginId,
    required this.id,
    required this.title,
    required this.value,
    this.size,
    this.url,
    this.details = const {},
  });

  factory Quality.fromJson(Map json) => Quality(
    pluginId: json['pluginId'],
    id: json['id'],
    title: json['title'],
    value: json['quality'],
    size: json['size'],
    url: json['url'],
    details: Map<String, dynamic>.from(json),
  );

  Map<String, dynamic> toJson() => {
    ...details,
    'pluginId': pluginId,
    'id': id,
    'title': title,
    'quality': value,
    'size': size,
    'url': url,
  };
}
