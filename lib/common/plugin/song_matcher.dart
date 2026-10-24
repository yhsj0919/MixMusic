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

  static List<String> _artists(Song song) {
    final names = switch (song.details['artist']) {
      List items when items.isNotEmpty => [
        for (final item in items) (item as Map)['title']?.toString() ?? '',
      ],
      _ => [song.subtitle ?? ''],
    };
    return names
        .expand((name) => name.split(RegExp(r'[,，、&＆/／;；|｜]')))
        .where((name) => normalize(name).isNotEmpty)
        .toList();
  }

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

  static double? _artistScore(Song original, Song candidate) {
    final singers = _artists(original);
    if (singers.isEmpty) return null;
    return _artists(candidate)
        .map((item) => similarity(singers.first, item))
        .fold<double>(0.0, max);
  }

  static double score(Song original, Song candidate) {
    final title = similarity(original.title, candidate.title);
    final artist = _artistScore(original, candidate);
    return artist == null ? title * 100 : title * 70 + artist * 30;
  }

  static bool matches(Song original, Song candidate) =>
      similarity(original.title, candidate.title) >= .85 &&
      (_artistScore(original, candidate) ?? 1) >= .8 &&
      _versions.every(
        (version) =>
            version.hasMatch(original.title) ==
            version.hasMatch(candidate.title),
      ) &&
      score(original, candidate) >= threshold;

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
          ..removeWhere(
            (item) =>
                item.score < minimum ||
                (minimum > 0 && !matches(original, item.song)),
          )
          ..sort(
            (a, b) => a.score == b.score
                ? a.index.compareTo(b.index)
                : b.score.compareTo(a.score),
          );
    return scored.map((item) => item.song).toList();
  }
}
