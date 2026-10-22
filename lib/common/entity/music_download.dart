import 'song.dart';

enum DownloadGrouping {
  none('不分类'),
  collection('按歌单／专辑'),
  artist('按歌手');

  const DownloadGrouping(this.label);
  final String label;

  String folder(Song song, {String? collection}) => switch (this) {
    DownloadGrouping.none => '',
    DownloadGrouping.collection => collection ?? '',
    DownloadGrouping.artist => switch (song.details['artist']) {
      [Map first, ...] => first['title']?.toString() ?? '',
      _ => '',
    },
  };
}

enum DownloadState {
  waiting,
  resolving,
  downloading,
  retrying,
  complete,
  cancelled,
  failed,
}

class MusicDownload {
  MusicDownload(
    this.song,
    this.key, {
    this.directory = '',
    this.folder = '',
    this.allowMatch = false,
  });
  final Song song;
  String key;
  final bool allowMatch;
  final String directory;
  final String folder;
  DownloadState state = DownloadState.waiting;
  int received = 0;
  int total = 0;
  int attempts = 0;
  String? path;
  String? error;
}
