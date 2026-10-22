import 'dart:math';

import 'package:collection/collection.dart';

import '../entity/song.dart';

class SongMatcher {
  static bool sameSong(Song a, Song b) =>
      a.pluginId == b.pluginId &&
      const DeepCollectionEquality().equals(a.id, b.id);
  static const threshold = 85.0;
  static final _versions = [
    RegExp(r'\blive\b|现场', caseSensitive: false),
    RegExp(r'伴奏|纯音乐|\binstrumental\b', caseSensitive: false),
    RegExp(r'翻唱|\bcover\b', caseSensitive: false),
    RegExp(r'\bremix\b|\bdj\b', caseSensitive: false),
    RegExp(r'加速|慢速|变速|\bsped\b|\bslowed\b', caseSensitive: false),
  ];

  static String normalize(String text) => String.fromCharCodes(
    text.runes.map(
      (code) => code >= 0xff01 && code <= 0xff5e ? code - 0xfee0 : code,
    ),
  ).toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  static String artist(Song song) => switch (song.details['artist']) {
    [Map first, ...] => first['title']?.toString() ?? '',
    _ => song.subtitle ?? '',
  };

  static double similarity(String left, String right) {
    final a = normalize(left).runes.toList(),
        b = normalize(right).runes.toList();
    if (a.isEmpty || b.isEmpty) return 0;
    var row = List.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final next = [i + 1];
      for (var j = 0; j < b.length; j++) {
        next.add(
          min(
            min(next[j] + 1, row[j + 1] + 1),
            row[j] + (a[i] == b[j] ? 0 : 1),
          ),
        );
      }
      row = next;
    }
    return 1 - row.last / max(a.length, b.length);
  }

  static double score(Song original, Song candidate) {
    for (final version in _versions) {
      if (version.hasMatch(original.title) !=
          version.hasMatch(candidate.title)) {
        return 0;
      }
    }
    final title = similarity(original.title, candidate.title);
    if (title < .85) return 0;
    final singer = artist(original);
    if (normalize(singer).isEmpty) return title * 100;
    final artists = switch (candidate.details['artist']) {
      List items when items.isNotEmpty => [
        for (final item in items) (item as Map)['title']?.toString() ?? '',
      ],
      _ => [candidate.subtitle ?? ''],
    };
    final artistScore = artists
        .map((item) => similarity(singer, item))
        .fold(0.0, max);
    if (artistScore < .8) return 0;
    return title * 70 + artistScore * 30;
  }

  static List<Song> rank(
    Song original,
    List<Song> candidates, {
    double minimum = threshold,
  }) {
    final scored =
        [
            for (var i = 0; i < candidates.length; i++)
              (
                song: candidates[i],
                score: score(original, candidates[i]),
                index: i,
              ),
          ]
          ..removeWhere((item) => item.score < minimum)
          ..sort(
            (a, b) => a.score == b.score
                ? a.index.compareTo(b.index)
                : b.score.compareTo(a.score),
          );
    return scored.map((item) => item.song).toList();
  }
}
