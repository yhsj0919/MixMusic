import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lemon_net/lemon_net.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entity/music_download.dart';
import '../entity/song.dart';
import '../player/music_cache.dart';
import '../plugin/plugin_controller.dart';
import 'download_files.dart';
import '../queue/hyper_queue.dart';
import '../plugin/collection_controller.dart';
import 'download_collection.dart';
import 'download_session.dart';
import 'download_store.dart';
import '../entity/quality.dart';
import '../queue/hyper_queue_entry.dart';

class DownloadController extends LxController {
  DownloadController(
    this.plugins, {
    this.directory,
    DownloadFiles? files,
    this.cache,
    this.preferences,
    DownloadStore? store,
    int retryCount = 2,
    this.retryDelay = const Duration(seconds: 1),
  }) : files = files ?? DownloadFiles() {
    this.retryCount = own(
      (preferences?.getInt('downloadRetries') ?? retryCount).obs,
    );
    if (store != null) {
      session = DownloadSession(this, store, onCollection: _collections.add);
    }
    restored = _restore();
  }
  final PluginController plugins;
  final DownloadFiles files;
  final MusicCache? cache;
  final SharedPreferences? preferences;
  late final Future<void> restored;
  DownloadSession? session;
  bool _closing = false;
  late final directoryError = own(''.obs);
  late final restoreError = own(''.obs);

  Future<void> _restore() async {
    await _restoreDirectory();
    if (session == null) return;
    try {
      await session!.restore();
    } catch (error, stack) {
      restoreError.value = '下载记录恢复失败，请查看下载日志';
      plugins.addLog('download', 'error', '恢复下载记录失败：$error\n$stack');
    }
  }

  Future<void> _restoreDirectory() async {
    try {
      await files.checkDirectory(selectedDirectory.value);
    } catch (error) {
      if (!isDisposed) directoryError.value = '下载目录不可用，请重新选择文件夹';
      plugins.addLog(
        'download',
        'warn',
        '[Download][DIRECTORY_UNAVAILABLE] $error',
      );
    }
  }

  late final defaultQuality = own(
    (preferences?.getInt('downloadQuality') ?? 128).obs,
  );
  late final allowMatch = own(
    (preferences?.getBool('downloadMatch') ?? false).obs,
  );

  Future<void> setAllowMatch(bool value) async {
    allowMatch.value = value;
    await preferences?.setBool('downloadMatch', value);
  }

  late final grouping = own(
    DownloadGrouping.values
        .firstWhere(
          (item) => item.name == preferences?.getString('downloadGrouping'),
          orElse: () => DownloadGrouping.none,
        )
        .obs,
  );

  Future<void> setGrouping(DownloadGrouping value) async {
    grouping.value = value;
    await preferences?.setString('downloadGrouping', value.name);
  }

  Future<void> setDefaultQuality(int value) async {
    defaultQuality.value = value;
    await preferences?.setInt('downloadQuality', value);
  }

  late final Rx<int> retryCount;
  final Duration retryDelay;
  final _collections = <DownloadCollection>[];
  final _sourceAttempts = <Object, int>{};
  CancelToken? _sourceCancel;
  Object? _retryingSource;
  Future<void>? _viewing;

  Future<void> loadMore({Object? key, bool retry = false}) =>
      _viewing ??= _viewPage(key, retry).whenComplete(() => _viewing = null);

  Future<void> _viewPage(Object? key, bool retry) async {
    for (final root in hyperQueue.roots.value) {
      final group = root.source?.key;
      if (group is! DownloadCollection || (key != null && group != key)) {
        continue;
      }
      final collection = group.collection;
      if (group.cancelled.value ||
          !collection.hasMore.value ||
          (!retry && collection.error.value.isNotEmpty)) {
        continue;
      }
      _logCollection(
        'VIEW_PAGE',
        group,
        'page=${collection.page}; metadata only',
      );
      await collection.loadMore();
      return;
    }
  }

  void _logCollection(String event, Object key, [String detail = '']) {
    if (isDisposed) return;
    final message =
        '[Download][$event] source=${identityHashCode(key).toRadixString(16)} $detail';
    debugPrint(message);
    plugins.addLog('download', 'log', message);
  }

  List<Quality> qualities(CollectionController collection) => {
    for (final song in collection.songs.value)
      for (final quality in song.qualities) quality.value: quality,
  }.values.toList();

  List<HyperQueueEntry<MusicDownload>> get entries => [
    for (final root in hyperQueue.roots.value) ...[
      root,
      if (root.source != null)
        for (final task in hyperQueue.itemsIn(root.source!.key))
          HyperQueueEntry(item: task),
    ],
  ];

  String collectionStatus(DownloadCollection group) {
    final tasks = hyperQueue.itemsIn(group);
    final complete = tasks
        .where((task) => task.state == DownloadState.complete)
        .length;
    final failed = tasks
        .where((task) => task.state == DownloadState.failed)
        .length;
    final paused = hyperQueue.roots.value.any(
      (entry) => entry.source?.key == group && entry.suspended,
    );
    final state = group.cancelled.value
        ? '已取消'
        : paused
        ? '已跳过'
        : group.collection.hasMore.value
        ? '按需加载'
        : '已加载全部';
    return '$state · 完成 $complete / ${tasks.length} 首${failed == 0 ? '' : ' · 失败 $failed 首'}';
  }

  void cancelCollection(Object key) {
    skipCollection(key);
    if (key is DownloadCollection) key.cancelled.value = true;
    for (final task in hyperQueue.itemsIn(key)) {
      if ([
        DownloadState.waiting,
        DownloadState.resolving,
        DownloadState.downloading,
        DownloadState.retrying,
      ].contains(task.state)) {
        cancel(task);
      }
    }
    _update();
    _logCollection('COLLECTION_CANCEL', key);
  }

  Future<void> setRetryCount(int value) async {
    if (value < 0) throw ArgumentError.value(value, 'retryCount');
    retryCount.value = value;
    await preferences?.setInt('downloadRetries', value);
    plugins.addLog('download', 'log', '[Download][SETTING] retries=$value');
    debugPrint('[Download][SETTING] retries=$value');
  }

  void addCollection(CollectionController collection, {int? quality}) {
    _pruneCollections();
    quality ??= defaultQuality.value;
    if (_collections.any(
      (group) => group.collection == collection && group.quality == quality,
    )) {
      return;
    }
    final group = own(
      DownloadCollection(
        collection,
        quality,
        directory: selectedDirectory.value,
        grouping: grouping.value,
        allowMatch: allowMatch.value,
      ),
    );
    _collections.add(group);
    hyperQueue.appendCollection(group.source);
    _logCollection('COLLECTION_QUEUED', group, 'quality=$quality');
    _start();
  }

  void _pruneCollections() {
    final active = hyperQueue.roots.value
        .map((entry) => entry.source?.key)
        .toSet();
    for (final group in _collections.toList()) {
      if (active.contains(group)) continue;
      _collections.remove(group);
      _sourceAttempts.remove(group);
      unawaited(group.dispose());
    }
  }

  void retryCollection(Object key) {
    _sourceAttempts.remove(key);
    if (key is DownloadCollection) {
      key.cancelled.value = false;
      for (final task in key.items.value) {
        if ([
          DownloadState.failed,
          DownloadState.cancelled,
        ].contains(task.state)) {
          task.state = DownloadState.waiting;
          task.attempts = 0;
          task.error = null;
        }
      }
    }
    hyperQueue.resume(key);
    _logCollection('COLLECTION_RETRY', key);
    _start();
  }

  void skipCollection(Object key) {
    hyperQueue.suspend(key);
    _logCollection('COLLECTION_SKIP', key);
    if (key is DownloadCollection && key.items.value.contains(_active)) {
      cancel(_active!);
    }
    if (_retryingSource == key) _sourceCancel?.cancel();
    _start();
  }

  Future<bool> _wait(CancelToken token) async {
    await Future.any([Future<void>.delayed(retryDelay), token.whenCancel]);
    return !token.isCancelled && !isDisposed;
  }

  Future<MusicDownload?> _nextTask() async {
    hyperQueue.index.value = -1;
    while (!isDisposed && !_closing) {
      final position = await hyperQueue.nextIndex(retry: true);
      if (isDisposed) return null;
      final source = hyperQueue.blockedSource;
      if (source != null) {
        final attempt = (_sourceAttempts[source.key] ?? 0) + 1;
        _sourceAttempts[source.key] = attempt;
        final skip = attempt > retryCount.value;
        final message =
            '[Download][SOURCE_${skip ? 'SKIP' : 'RETRY'}] source=${identityHashCode(source.key).toRadixString(16)} attempt=$attempt/${retryCount.value + 1}; page failed';
        debugPrint(message);
        plugins.addLog('download', 'warn', message);
        if (skip) {
          hyperQueue.suspend(source.key);
        } else {
          final token = _sourceCancel = CancelToken();
          _retryingSource = source.key;
          await _wait(token);
          _sourceCancel = null;
          _retryingSource = null;
        }
        continue;
      }
      if (position == null) return null;
      final task = tasks.value[position];
      for (final group in _collections) {
        if (group.collection.error.value.isEmpty &&
            group.items.value.contains(task)) {
          _sourceAttempts.remove(group);
        }
      }
      hyperQueue.index.value = position;
      if (task.state == DownloadState.waiting) return task;
    }
    return null;
  }

  Directory? directory;
  late final selectedDirectory = own(
    (directory?.path ?? preferences?.getString('downloadDirectory') ?? '').obs,
  );

  Future<void> selectDirectory() async {
    final path = await files.pickDirectory();
    if (path != null) await setDirectory(path);
  }

  Future<void> setDirectory(String path) async {
    final uri = Uri.tryParse(path);
    final selected = path.startsWith('content:')
        ? path
        : (uri?.scheme == 'file' ? Directory.fromUri(uri!) : Directory(path))
              .absolute
              .path;
    if (!selected.startsWith('content:')) {
      await Directory(selected).create(recursive: true);
    }
    await files.checkDirectory(selected);
    if (isDisposed) return;
    selectedDirectory.value = selected;
    directoryError.value = '';
    await preferences?.setString('downloadDirectory', selected);
    debugPrint('[Download][DIRECTORY] selected');
    plugins.addLog(
      'download',
      'log',
      '[Download][DIRECTORY] selected; new tasks use new directory',
    );
  }

  final net = LemonNet('');
  late final hyperQueue = own(
    HyperQueue<MusicDownload>(
      same: (a, b) => a.key == b.key,
      snapshot: (task) => task,
    ),
  );
  Rx<List<MusicDownload>> get tasks => hyperQueue.items;
  CancelToken? _cancel;
  MusicDownload? _active;
  Future<void>? _running;

  void _log(String event, MusicDownload task, [String detail = '']) {
    if (isDisposed) return;
    final message =
        '[Download][$event] ${task.song.pluginId} '
        'quality=${task.song.playQuality} key=${task.key.substring(0, 12)} attempt=${task.attempts}/${retryCount.value + 1} $detail';
    debugPrint(message);
    plugins.addLog('download', 'log', message);
  }

  void _update() {
    if (!isDisposed) tasks.refresh();
    session?.changed();
  }

  MusicDownload add(Song song, {int? quality}) {
    final selected = Song.fromJson(song.toJson())
      ..playQuality =
          song.matchedSong?.playQuality ?? quality ?? defaultQuality.value
      ..url = null;
    final key = MusicCache.keyFor(selected);
    for (final task in tasks.value) {
      if (task.key == key) return task;
    }
    final task = MusicDownload(
      selected,
      key,
      directory: selectedDirectory.value,
      folder: grouping.value.folder(selected),
    );
    hyperQueue.append(task);
    _log('QUEUED', task);
    _start();
    return task;
  }

  void _start() {
    if (_running != null || isDisposed || _closing) return;
    _running = _drain().whenComplete(() => _running = null);
  }

  Future<void> _drain() async {
    await restored;
    if (restoreError.value.isNotEmpty) return;
    while (!isDisposed && !_closing) {
      final task = await _nextTask();
      if (task == null || isDisposed || _closing) return;
      _active = task;
      final token = _cancel = CancelToken();
      File? temporary;
      try {
        task.attempts++;
        await restored;
        task.received = 0;
        task.total = 0;
        var targetDirectory = task.directory.isNotEmpty
            ? task.directory
            : '${(await getApplicationDocumentsDirectory()).path}/MixMusic/downloads';
        if (!targetDirectory.startsWith('content:')) {
          await Directory(targetDirectory).create(recursive: true);
        }
        await files.checkDirectory(targetDirectory);
        final folder = DownloadFiles.folderName(task.folder);
        if (folder.isNotEmpty) {
          try {
            targetDirectory = await files.createFolder(targetDirectory, folder);
          } catch (error) {
            _log('FOLDER_FALLBACK', task, 'use root; ${error.runtimeType}');
          }
        }
        if (token.isCancelled || isDisposed) continue;
        final existing = await files.find(targetDirectory, task.key);
        if (token.isCancelled || isDisposed) continue;
        if (existing != null) {
          task.path = existing.path;
          task.received = task.total = existing.bytes;
          task.state = DownloadState.complete;
          _log('SKIP_EXISTING', task, 'bytes=${existing.bytes}');
          continue;
        }
        final staging = targetDirectory.startsWith('content:')
            ? (await getTemporaryDirectory()).path
            : targetDirectory;
        final name = task.song.title
            .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
            .replaceAll(RegExp(r'[. ]+$'), '');
        final base =
            '$staging/${name.isEmpty ? 'music' : name}-${task.key.substring(0, 12)}';
        temporary = File('$base.part');
        task.state = DownloadState.resolving;
        _update();
        var lastPercent = -1;
        void progress(int received, int total, {bool copying = false}) {
          if (isDisposed || token.isCancelled) return;
          if (copying && task.state != DownloadState.downloading) {
            task.state = DownloadState.downloading;
            _log('CACHE_COPY', task);
          }
          task.received = received;
          task.total = total;
          _update();
          final percent = total > 0 ? received * 10 ~/ total : -1;
          if (percent != lastPercent) {
            lastPercent = percent;
            _log(
              copying ? 'COPY_PROGRESS' : 'PROGRESS',
              task,
              'received=$received total=$total',
            );
          }
        }

        _log('CACHE_LOOKUP', task);
        var cached = await cache?.copyTo(
          task.song,
          temporary,
          cancelled: () => token.isCancelled || isDisposed,
          onProgress: (received, total) =>
              progress(received, total, copying: true),
        );
        if (token.isCancelled || isDisposed) continue;
        String? mime;
        var suffix = '';
        if (cached != null) {
          mime = cached.mime;
          _log(
            'CACHE_HIT',
            task,
            'skip playUrl/network; bytes=${cached.bytes}',
          );
        } else {
          _log('CACHE_MISS', task);
          task.state = DownloadState.resolving;
          _update();
          _log('RESOLVE', task, 'request fresh playUrl');
          Future<Song> load(Song candidate) async {
            if (token.isCancelled || isDisposed) throw StateError('下载已取消');
            cached = await cache?.copyTo(
              candidate,
              temporary!,
              cancelled: () => token.isCancelled || isDisposed,
              onProgress: (received, total) =>
                  progress(received, total, copying: true),
            );
            if (token.isCancelled || isDisposed) throw StateError('下载已取消');
            if (cached != null) {
              return Song.fromJson(candidate.toJson())
                ..url = temporary!.uri.toString();
            }
            return plugins
                .music(candidate.pluginId)
                .playUrl(Song.fromJson(candidate.toJson())..url = null);
          }

          final source = task.song.matchedSong != null
              ? await load(task.song.actualSong)
              : await plugins.matcher.resolve(
                  task.song,
                  load,
                  allowMatch: task.allowMatch,
                  cancelled: () => token.isCancelled || isDisposed,
                );
          task.key = MusicCache.keyFor(source);
          task.song.playQuality = source.playQuality;
          if (source.pluginId != task.song.pluginId) {
            task.song.matchedSong = source;
          }
          if (token.isCancelled || isDisposed) continue;
          final found = await files.find(targetDirectory, task.key);
          if (found != null) {
            task.path = found.path;
            task.received = task.total = found.bytes;
            task.state = DownloadState.complete;
            _log('SKIP_EXISTING', task, 'actual source; bytes=${found.bytes}');
            continue;
          }
          if (cached != null) {
            mime = cached!.mime;
            _log('CACHE_HIT', task, 'matched source; skip network');
          } else {
            final uri = Uri.tryParse(source.url ?? '');
            if (uri == null || !['http', 'https'].contains(uri.scheme)) {
              throw StateError('未返回可下载的 HTTP 地址');
            }
            if (uri.path.toLowerCase().endsWith('.m3u8') ||
                uri.path.toLowerCase().endsWith('.mpd')) {
              throw StateError('暂不支持分段资源下载');
            }
            suffix = uri.pathSegments.isEmpty
                ? ''
                : uri.pathSegments.last.split('.').last.toLowerCase();
            task.state = DownloadState.downloading;
            _update();
            _log('START', task);
            final response = await net.download(
              source.url!,
              temporary.path,
              cancelToken: token,
              options: Options(
                headers: Map<String, dynamic>.from(
                  source.details['httpHeaders'] as Map? ?? {},
                ),
                validateStatus: (status) => status == 200,
              ),
              onReceiveProgress: progress,
            );
            if (token.isCancelled || isDisposed) continue;
            mime = response.headers
                .value('content-type')
                ?.split(';')
                .first
                .trim()
                .toLowerCase();
          }
        }
        if (mime == null || mime == 'application/octet-stream') {
          final reader = await temporary.open();
          try {
            mime =
                lookupMimeType('', headerBytes: await reader.read(256)) ?? mime;
          } finally {
            await reader.close();
          }
        }
        if (mime != null &&
            mime != 'application/octet-stream' &&
            mime != 'application/ogg' &&
            mime != 'application/mp4' &&
            !mime.startsWith('audio/')) {
          throw StateError('返回内容不是音频文件');
        }
        const extensions = {
          'audio/mpeg': 'mp3',
          'audio/flac': 'flac',
          'audio/x-flac': 'flac',
          'audio/mp4': 'm4a',
          'audio/aac': 'aac',
          'audio/ogg': 'ogg',
          'audio/wav': 'wav',
          'audio/x-wav': 'wav',
          'audio/opus': 'opus',
          'application/ogg': 'ogg',
          'application/mp4': 'm4a',
        };
        final extension =
            extensions[mime] ??
            (extensions.values.contains(suffix) ? suffix : null);
        if (extension == null) throw StateError('无法确认音频文件格式');
        if (task.received == 0) throw StateError('返回的音频文件为空');
        final bytes = await temporary.length();
        if (bytes != task.received || (task.total > 0 && bytes != task.total)) {
          throw StateError('音频文件未下载完整');
        }
        if (token.isCancelled || isDisposed) continue;
        task.path = await files.save(
          temporary,
          targetDirectory,
          '${name.isEmpty ? 'music' : name}-${task.key.substring(0, 12)}.$extension',
          mime ?? 'application/octet-stream',
        );
        task.state = DownloadState.complete;
        _log('COMPLETE', task, 'bytes=${task.received}');
      } catch (error) {
        task.state = token.isCancelled || isDisposed
            ? DownloadState.cancelled
            : task.attempts <= retryCount.value
            ? DownloadState.retrying
            : DownloadState.failed;
        task.error = token.isCancelled
            ? null
            : error is StateError
            ? error.message.toString()
            : error is DioException
            ? '下载失败：${error.response?.statusCode ?? error.type.name}'
            : error is PlatformException
            ? error.message ?? '下载目录不可用，请重新选择文件夹'
            : '下载失败：${error.runtimeType}';
        _log(
          token.isCancelled
              ? 'CANCELLED'
              : task.state == DownloadState.retrying
              ? 'AUTO_RETRY'
              : 'SKIP',
          task,
          task.error ?? '',
        );
      } finally {
        try {
          if (temporary != null && await temporary.exists()) {
            await temporary.delete();
          }
        } catch (error) {
          _log('CLEANUP_ERROR', task, '${error.runtimeType}');
        }
        _active = null;
        _cancel = null;
        _update();
      }
      if (task.state == DownloadState.retrying) {
        _active = task;
        _cancel = token;
        if (await _wait(token) && task.state == DownloadState.retrying) {
          if (task.attempts > retryCount.value) {
            task.state = DownloadState.failed;
            _log('SKIP', task, 'retry limit changed');
          } else {
            task.state = DownloadState.waiting;
          }
        }
      }
      _active = null;
      _cancel = null;
      _update();
    }
  }

  void cancel(MusicDownload task) {
    if (task.state == DownloadState.complete) return;
    task.state = DownloadState.cancelled;
    if (identical(_active, task)) _cancel?.cancel();
    _log('CANCEL', task);
    _update();
  }

  void retry(MusicDownload task) {
    if ((identical(_active, task) && task.state != DownloadState.failed) ||
        ![DownloadState.failed, DownloadState.cancelled].contains(task.state)) {
      return;
    }
    task.state = DownloadState.waiting;
    task.error = null;
    task.received = 0;
    task.total = 0;
    task.attempts = 0;
    for (final root in hyperQueue.roots.value) {
      final key = root.source?.key;
      if (root.suspended &&
          key != null &&
          hyperQueue.itemsIn(key).contains(task)) {
        _sourceAttempts.remove(key);
        if (key is DownloadCollection) key.cancelled.value = false;
        hyperQueue.resume(key);
        break;
      }
    }
    _update();
    _log('RETRY', task, 'resolve again when started');
    _start();
  }

  void remove(MusicDownload task) {
    if (identical(_active, task)) return;
    final index = tasks.value.indexOf(task);
    if (index >= 0) hyperQueue.remove(index);
    _pruneCollections();
    _log('REMOVE', task, 'keep downloaded file');
  }

  @override
  Future<void> onDispose() async {
    for (final group in _collections) {
      await group.dispose();
    }
  }

  @override
  Future<void> disposeController() async {
    if (isDisposed || _closing) return;
    _closing = true;
    _cancel?.cancel();
    _sourceCancel?.cancel();
    net.close(force: true);
    await _running;
    await restored;
    await session?.dispose();
    await super.disposeController();
  }
}
