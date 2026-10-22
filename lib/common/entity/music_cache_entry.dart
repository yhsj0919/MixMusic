class MusicCacheEntry {
  String key;
  int bytes;
  int lastUsed;
  String? mime;

  MusicCacheEntry(this.key, this.bytes, this.lastUsed, {this.mime});
  MusicCacheEntry.fromJson(Map json)
    : key = json['key'],
      bytes = json['bytes'],
      lastUsed = json['lastUsed'],
      mime = json['mime'];
  Map<String, dynamic> toJson() => {
    'key': key,
    'bytes': bytes,
    'lastUsed': lastUsed,
    'mime': mime,
  };
}
