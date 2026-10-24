import 'dart:async';
import 'dart:convert';

import 'package:lemon_x/lemon_x.dart';

import '../entity/album.dart';
import '../entity/artist.dart';
import '../entity/music_collection.dart';
import '../entity/music_download.dart';
import '../entity/play_list.dart';
import '../entity/rank.dart';
import '../entity/song.dart';
import '../plugin/collection_controller.dart';
import '../queue/hyper_queue_source.dart';
import 'download_collection.dart';
import 'download_controller.dart';
import 'download_store.dart';

class DownloadSession implements LxDisposable {
  DownloadSession(this.controller, this.store, {required this.onCollection});
  final DownloadController controller;
  final DownloadStore store;
  final void Function(DownloadCollection) onCollection;
  bool _restored = false;
  Timer? _timer;
  Future<void> _writing = Future.value();

  static dynamic _clean(dynamic value) {
    if (value is List) return value.map(_clean).toList();
    if (value is! Map) return value;
    return {
      for (final entry in value.entries)
        if (![
          'url',
          'httpHeaders',
          'headers',
          'cookie',
          'cookies',
          'playUrl',
          'downloadUrl',
        ].contains(entry.key))
          '${entry.key}': entry.key == 'id' ? entry.value : _clean(entry.value),
    };
  }

  Map<String, dynamic> snapshot() {
    final records = <MusicDownload, int>{};
    final tasks = <Map<String, dynamic>>[];
    Map reference(MusicDownload task) {
      final id = records.putIfAbsent(task, () {
        tasks.add({
          'song': _clean(task.song.toJson()),
          'key': task.key,
          'directory': task.directory,
          'folder': task.folder,
          'allowMatch': task.allowMatch,
          'state': task.state.name,
          'received': task.received,
          'total': task.total,
          'attempts': task.attempts,
          'path': task.path,
          'error': task.error,
        });
        return tasks.length - 1;
      });
      return {'task': id};
    }

    final queue = controller.hyperQueue.toSnapshot(
      item: reference,
      source: (source) {
        final group = source.key as DownloadCollection;
        final collection = group.collection;
        return {
          'kind': collection.kind.name,
          'resource': _clean(collection.resource.toJson()),
          'songs': collection.songs.value
              .map((song) => _clean(song.toJson()))
              .toList(),
          'page': collection.page,
          'hasMore': collection.hasMore.value,
          'quality': group.quality,
          'directory': group.directory,
          'grouping': group.grouping.name,
          'allowMatch': group.allowMatch,
          'cancelled': group.cancelled.value,
          'items': group.items.value.map(reference).toList(),
        };
      },
    );
    // 立即拷贝，后续状态变化不改动正在排队写入的快照。
    return jsonDecode(jsonEncode({'queue': queue, 'tasks': tasks}))
        as Map<String, dynamic>;
  }

  Future<void> restore() async {
    final saved = await store.load();
    if (saved != null && !controller.isDisposed) {
      final tasks = (saved['tasks'] as List).map((value) {
        final data = value as Map;
        final state = DownloadState.values.byName(data['state'] as String);
        return MusicDownload(
            Song.fromJson(data['song'] as Map),
            data['key'] as String,
            directory: data['directory'] as String,
            folder: data['folder'] as String,
            allowMatch: data['allowMatch'] as bool,
          )
          ..state =
              [
                DownloadState.waiting,
                DownloadState.resolving,
                DownloadState.downloading,
                DownloadState.retrying,
              ].contains(state)
              ? DownloadState.cancelled
              : state
          ..received = data['received'] as int
          ..total = data['total'] as int
          ..attempts = data['attempts'] as int
          ..path = data['path'] as String?
          ..error = data['error'] as String?;
      }).toList();
      MusicDownload task(Map value) => tasks[value['task'] as int];
      final pending = controller.hyperQueue.toSnapshot(
        item: (item) => {'instance': item},
        source: (source) => {'instance': source},
      );
      HyperQueueSource<MusicDownload> source(Map data) {
        final kind = CollectionKind.values.byName(data['kind'] as String);
        final json = data['resource'] as Map;
        final resource = switch (kind) {
          CollectionKind.playlist => PlayList.fromJson(json),
          CollectionKind.album => Album.fromJson(json),
          CollectionKind.artist => Artist.fromJson(json),
          CollectionKind.rank => Rank.fromJson(json),
          _ => MusicCollection.fromJson(json),
        };
        final collection = controller.plugins.collection(kind, resource);
        collection.page = data['page'] as int;
        collection.hasMore.value = data['hasMore'] as bool;
        collection.songs.value = (data['songs'] as List)
            .map((song) => Song.fromJson(song as Map))
            .toList();
        final group = controller.own(
          DownloadCollection(
            collection,
            data['quality'] as int?,
            directory: data['directory'] as String,
            grouping: DownloadGrouping.values.byName(
              data['grouping'] as String,
            ),
            allowMatch: data['allowMatch'] as bool,
          ),
        );
        group.items.value = (data['items'] as List)
            .map((item) => task(item as Map))
            .toList();
        group.cancelled.value = data['cancelled'] as bool;
        onCollection(group);
        return group.source;
      }

      // 恢复期间新加入的任务放到末尾，不丢失用户操作。
      Map decode(Map node) => node.containsKey('item')
          ? {
              'item': {'instance': task(node['item'] as Map)},
            }
          : {
              ...node,
              'source': {'instance': source(node['source'] as Map)},
              'children': (node['children'] as List)
                  .map((child) => decode(child as Map))
                  .toList(),
              'suspended': true,
            };
      controller.hyperQueue.restoreSnapshot(
        {
          'index': -1,
          'roots': [
            ...((saved['queue'] as Map)['roots'] as List).map(
              (root) => decode(root as Map),
            ),
            ...pending['roots'] as List,
          ],
        },
        item: (value) => value['instance'] as MusicDownload,
        source: (value) => value['instance'] as HyperQueueSource<MusicDownload>,
      );
    }
    _restored = true;
    controller.hyperQueue.entries.addListener(changed);
  }

  void changed() {
    if (!_restored || (_timer?.isActive ?? false)) return;
    _timer = Timer(const Duration(seconds: 1), () => unawaited(save()));
  }

  Future<void> save() {
    _timer?.cancel();
    if (!_restored) return _writing;
    final data = snapshot();
    return _writing = _writing.then((_) => store.save(data)).catchError((
      Object error,
      StackTrace stack,
    ) {
      controller.plugins.addLog('download', 'error', '保存下载记录失败：$error\n$stack');
    });
  }

  @override
  Future<void> dispose() async {
    controller.hyperQueue.entries.removeListener(changed);
    await save();
  }
}
