import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entity/music_cache_entry.dart';
import '../entity/song.dart';

class MusicCache extends LxController implements LxDisposable {
  MusicCache({this.directory, this.onLog, this.preferences});
  final SharedPreferences? preferences;
  Directory? directory;
  final void Function(String)? onLog;
  late final enabled = own((preferences?.getBool('cacheEnabled') ?? true).obs);
  late final limitBytes = own(
    (preferences?.getInt('cacheLimit') ?? 512 * 1024 * 1024).obs,
  );
  late final usedBytes = own(0.obs);
  late final restored = _restore();
  final _entries = <String, MusicCacheEntry>{};
  final _sources = <String, Song>{};
  final _writing = <String>{};
  final _readers = <String, int>{};
  final _removing = <String>{};
  final _requests = <Future<void>>{};
  final _client = HttpClient()..autoUncompress = false;
  HttpServer? _server;
  Future<HttpServer>? _starting;
  Future<void> _saving = Future.value();
  String? _activeKey;
  int _generation = 0;

  static Object? _canonical(Object? value) => switch (value) {
    Map map => {
      for (final key in (map.keys.cast<String>().toList()..sort()))
        key: _canonical(map[key]),
    },
    List list => list.map(_canonical).toList(),
    _ => value,
  };
  static String keyFor(Song song) => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            song.actualSong.pluginId,
            _canonical(song.actualSong.id),
            song.actualSong.playQuality,
          ]),
        ),
      )
      .toString();

  void _log(String event, String detail) {
    if (isDisposed) return;
    final message = '[MusicCache][$event] $detail';
    debugPrint(message);
    onLog?.call(message);
  }

  String _tag(Song song) =>
      '${song.pluginId} quality=${song.playQuality ?? 'unknown'} key=${keyFor(song).substring(0, 12)}';
  File _file(String key, [String suffix = 'audio']) =>
      File('${directory!.path}/$key.$suffix');

  Future<void> _restore() async {
    directory ??= Directory(
      '${(await getApplicationSupportDirectory()).path}/music_cache',
    );
    await directory!.create(recursive: true);
    final index = File('${directory!.path}/index.json');
    if (await index.exists()) {
      final data = jsonDecode(await index.readAsString()) as Map;
      if (isDisposed) return;
      enabled.value =
          preferences?.getBool('cacheEnabled') ??
          data['enabled'] as bool? ??
          true;
      limitBytes.value =
          preferences?.getInt('cacheLimit') ??
          data['limitBytes'] as int? ??
          512 * 1024 * 1024;
      for (final row in data['entries'] as List) {
        final entry = MusicCacheEntry.fromJson(row as Map);
        if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(entry.key)) continue;
        final file = _file(entry.key);
        if (await file.exists() && await file.length() == entry.bytes) {
          _entries[entry.key] = entry;
        }
      }
    }
    await for (final item in directory!.list()) {
      if (item is File &&
          RegExp(r'^[a-f0-9]{64}\.part$')
              .hasMatch(item.uri.pathSegments.last)) {
        await item.delete();
      }
    }
    if (isDisposed) return;
    await preferences?.setBool('cacheEnabled', enabled.value);
    await preferences?.setInt('cacheLimit', limitBytes.value);
    _updateSize();
    _log(
      'RESTORE',
      'complete=${_entries.length} bytes=${usedBytes.value} limit=${limitBytes.value}',
    );
  }

  void _updateSize() => usedBytes.value = _entries.values.fold(
    0,
    (sum, entry) => sum + entry.bytes,
  );

  Future<void> _save() {
    final data = jsonEncode({
      if (preferences == null) 'enabled': enabled.value,
      if (preferences == null) 'limitBytes': limitBytes.value,
      'entries': _entries.values.map((entry) => entry.toJson()).toList(),
    });
    Future<void> write() async {
      final temp = File('${directory!.path}/index.tmp');
      await temp.writeAsString(data, flush: true);
      await temp.rename('${directory!.path}/index.json');
    }

    return _saving = _saving.then(
      (_) => write(),
      onError: (Object error) => write(),
    );
  }

  Future<Song> resolve(Song selected, Future<Song> Function() load) async {
    try {
      await restored;
    } catch (error) {
      _log('UNAVAILABLE', '${error.runtimeType}; use original source');
      return load();
    }
    if (isDisposed) return selected;
    if (!enabled.value) {
      _log('BYPASS', 'disabled ${_tag(selected)}');
      return load();
    }
    final key = keyFor(selected);
    final entry = _entries[key];
    if (entry != null) {
      final file = _file(key);
      if (await file.exists() && await file.length() == entry.bytes) {
        entry.lastUsed = DateTime.now().millisecondsSinceEpoch;
        await _save().catchError(
          (Object error) => _log('INDEX_ERROR', '${error.runtimeType}'),
        );
        _log(
          'HIT',
          '${_tag(selected)} bytes=${entry.bytes}; skip playUrl/network',
        );
        return Song.fromJson(selected.toJson())
          ..url = file.uri.toString()
          ..details = {...selected.details, 'httpHeaders': <String, String>{}};
      }
      _entries.remove(key);
      _updateSize();
      _log('INVALID', '${_tag(selected)} file missing or size changed');
    }
    _log('MISS', '${_tag(selected)}; request playUrl');
    final source = await load();
    if (isDisposed) return source;
    final uri = Uri.tryParse(source.url ?? '');
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.path.toLowerCase().endsWith('.m3u8') ||
        uri.path.toLowerCase().endsWith('.mpd')) {
      _log('BYPASS', '${_tag(source)} unsupported resource');
      return source;
    }
    try {
      final server = await (_starting ??= _start());
      if (isDisposed) return source;
      final token = List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      _sources[token] = source;
      _log('PROXY', '${_tag(source)}; stream once, write while playing');
      return Song.fromJson(source.toJson())
        ..url = 'http://127.0.0.1:${server.port}/$token';
    } catch (error) {
      _log('UNAVAILABLE', '${error.runtimeType}; use original source');
      return source;
    }
  }

  Future<MusicCacheEntry?> copyTo(
    Song selected,
    File destination, {
    bool Function()? cancelled,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await restored;
    } catch (error) {
      _log('COPY_UNAVAILABLE', '${error.runtimeType}');
      return null;
    }
    if (isDisposed || !enabled.value) return null;
    final key = keyFor(selected);
    final entry = _entries[key];
    if (entry == null || _removing.contains(key)) return null;
    _readers.update(key, (count) => count + 1, ifAbsent: () => 1);
    RandomAccessFile? output;
    bool stopped() => isDisposed || (cancelled?.call() ?? false);
    try {
      final file = _file(key);
      final valid = await file.exists() && await file.length() == entry.bytes;
      if (stopped()) return null;
      if (!valid) {
        _entries.remove(key);
        _updateSize();
        await _save();
        _log('COPY_INVALID', '${_tag(selected)} missing or size changed');
        return null;
      }
      output = await destination.open(mode: FileMode.write);
      _log('COPY_START', '${_tag(selected)} bytes=${entry.bytes}');
      var received = 0;
      await for (final chunk in file.openRead()) {
        if (stopped()) {
          _log('COPY_CANCELLED', _tag(selected));
          return null;
        }
        await output.writeFrom(chunk);
        received += chunk.length;
        onProgress?.call(received, entry.bytes);
      }
      if (stopped()) {
        _log('COPY_CANCELLED', _tag(selected));
        return null;
      }
      if (received != entry.bytes) throw StateError('缓存文件大小发生变化');
      await output.close();
      output = null;
      if (stopped()) return null;
      entry.lastUsed = DateTime.now().millisecondsSinceEpoch;
      await _save().catchError(
        (Object error) => _log('INDEX_ERROR', '${error.runtimeType}'),
      );
      _log('COPY_COMPLETE', '${_tag(selected)} bytes=$received');
      return entry;
    } finally {
      await output?.close();
      final readers = _readers[key]! - 1;
      if (readers == 0) {
        _readers.remove(key);
      } else {
        _readers[key] = readers;
      }
    }
  }

  Future<HttpServer> _start() async {
    final server = _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    server.listen((request) {
      final task = _serve(request);
      _requests.add(task);
      unawaited(task.whenComplete(() => _requests.remove(task)));
    });
    return server;
  }

  Future<void> _serve(HttpRequest request) async {
    final source = _sources[request.uri.path.substring(1)];
    if (source == null || !['GET', 'HEAD'].contains(request.method)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final key = keyFor(source);
    final generation = _generation;
    RandomAccessFile? output;
    StreamIterator<List<int>>? input;
    bool ownsWrite = false;
    bool committed = false;
    int received = 0;
    try {
      final upstream = await _client.openUrl(
        request.method,
        Uri.parse(source.url!),
      );
      final headers = Map<String, String>.from(
        source.details['httpHeaders'] as Map? ?? {},
      );
      headers.forEach(upstream.headers.set);
      upstream.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      for (final name in [HttpHeaders.rangeHeader, HttpHeaders.ifRangeHeader]) {
        final value = request.headers.value(name);
        if (value != null) upstream.headers.set(name, value);
      }
      final response = await upstream.close();
      input = StreamIterator(response);
      final hasFirst = request.method == 'GET' && await input.moveNext();
      final first = hasFirst ? input.current : const <int>[];
      final mime = response.headers.contentType?.mimeType ?? '';
      final prefix = ascii
          .decode(first.take(64).toList(), allowInvalid: true)
          .trimLeft();
      if (mime.contains('mpegurl') ||
          mime.contains('dash+xml') ||
          prefix.startsWith('#EXTM3U') ||
          prefix.startsWith('<?xml')) {
        _log('BYPASS', '${_tag(source)} segmented/manifest resource');
        await request.response.redirect(Uri.parse(source.url!));
        return;
      }
      request.response.statusCode = response.statusCode;
      response.headers.forEach((name, values) {
        if (!['connection', 'transfer-encoding', 'keep-alive'].contains(name)) {
          request.response.headers.set(name, values);
        }
      });
      final length = response.contentLength;
      final encoding = response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      final range = response.headers.value(HttpHeaders.contentRangeHeader);
      final match = range == null
          ? null
          : RegExp(r'^bytes 0-(\d+)/(\d+)$').firstMatch(range);
      final whole =
          response.statusCode == 200 ||
          (response.statusCode == 206 &&
              match != null &&
              int.parse(match[1]!) + 1 == int.parse(match[2]!) &&
              int.parse(match[2]!) == length);
      final audio =
          mime.startsWith('audio/') ||
          [
            'application/octet-stream',
            'application/mp4',
            'application/ogg',
          ].contains(mime);
      if (request.method == 'GET' &&
          (encoding == null || encoding == 'identity') &&
          enabled.value &&
          whole &&
          audio &&
          length > 0 &&
          length <= limitBytes.value &&
          !_writing.contains(key)) {
        _writing.add(key);
        ownsWrite = true;
        try {
          output = await _file(key, 'part').open(mode: FileMode.write);
          _log('WRITE_START', '${_tag(source)} expected=$length');
        } catch (error) {
          _log(
            'WRITE_ERROR',
            '${_tag(source)} ${error.runtimeType}; playback continues',
          );
        }
      } else {
        _log(
          'SKIP_WRITE',
          '${_tag(source)} method=${request.method} status=${response.statusCode} whole=$whole bytes=$length mime=$mime',
        );
      }
      Stream<List<int>> forward() async* {
        if (!hasFirst) return;
        var chunk = first;
        do {
          received += chunk.length;
          if (output != null) {
            try {
              await output!.writeFrom(chunk);
            } catch (error) {
              await output!.close();
              output = null;
              _log(
                'WRITE_ERROR',
                '${_tag(source)} ${error.runtimeType}; playback continues',
              );
            }
          }
          yield chunk;
          if (!await input!.moveNext()) break;
          chunk = input!.current;
        } while (true);
      }

      await request.response.addStream(forward());
      await request.response.close();
      if (output != null) {
        await output!.close();
        output = null;
        if (!isDisposed &&
            generation == _generation &&
            enabled.value &&
            received == length) {
          await _file(key, 'part').rename(_file(key).path);
          if (isDisposed ||
              generation != _generation ||
              received > limitBytes.value) {
            await _file(key).delete();
            return;
          }
          _entries[key] = MusicCacheEntry(
            key,
            received,
            DateTime.now().millisecondsSinceEpoch,
            mime: mime == 'application/octet-stream'
                ? lookupMimeType(Uri.parse(source.url!).path) ?? mime
                : mime,
          );
          committed = true;
          _updateSize();
          await _trim();
          await _save();
          _log('WRITE_COMPLETE', '${_tag(source)} bytes=$received');
        }
      }
    } catch (error) {
      _log(
        'TRANSFER_STOP',
        '${_tag(source)} received=$received ${error.runtimeType}; incomplete is not cached',
      );
      request.response.deadline = Duration.zero;
    } finally {
      await input?.cancel();
      await output?.close();
      if (ownsWrite) {
        if (!committed && await _file(key, 'part').exists()) {
          await _file(key, 'part').delete();
        }
        _writing.remove(key);
        if (!committed) {
          _log('WRITE_DISCARD', '${_tag(source)} bytes=$received');
        }
      }
    }
  }

  Future<void> setEnabled(bool value) async {
    await restored;
    enabled.value = value;
    await preferences?.setBool('cacheEnabled', value);
    _generation++;
    await _save();
    _log('SETTING', 'enabled=$value');
  }

  Future<void> setLimit(int bytes) async {
    if (bytes <= 0) throw ArgumentError.value(bytes, 'bytes');
    await restored;
    limitBytes.value = bytes;
    await preferences?.setInt('cacheLimit', bytes);
    await _trim();
    await _save();
    _log('SETTING', 'limit=$bytes');
  }

  Future<void> _remove(MusicCacheEntry entry) async {
    if (_readers.containsKey(entry.key)) return;
    _removing.add(entry.key);
    try {
      final file = _file(entry.key);
      if (await file.exists()) await file.delete();
      _entries.remove(entry.key);
      _updateSize();
    } finally {
      _removing.remove(entry.key);
    }
  }

  Future<void> _trim() async {
    final entries = _entries.values.toList()
      ..sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
    for (final entry in entries) {
      if (usedBytes.value <= limitBytes.value) break;
      if (entry.key == _activeKey ||
          _writing.contains(entry.key) ||
          _readers.containsKey(entry.key)) {
        continue;
      }
      await _remove(entry);
      _log('EVICT', 'key=${entry.key.substring(0, 12)} bytes=${entry.bytes}');
    }
  }

  Future<void> clear() async {
    await restored;
    _generation++;
    var removed = 0;
    for (final entry in _entries.values.toList()) {
      if (entry.key == _activeKey ||
          _writing.contains(entry.key) ||
          _readers.containsKey(entry.key)) {
        continue;
      }
      await _remove(entry);
      removed++;
    }
    await _save();
    _log(
      'CLEAR',
      'removed=$removed remaining=${_entries.length}; current/copying files protected',
    );
  }

  void activate(Song song) => _activeKey = keyFor(song);
  void release() => _activeKey = null;

  @override
  Future<void> dispose() async {
    await disposeController();
  }

  @override
  Future<void> onDispose() async {
    await _server?.close(force: true);
    _client.close(force: true);
    await Future.wait(_requests.toList());
    await _saving;
    _sources.clear();
  }
}
