import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/library/library_controller.dart';

class LibraryApi extends MusicApi {
  LibraryApi(super.manager, super.pluginId);
  Completer<void>? gate;
  int albumReads = 0, playlistReads = 0;
  final created = <String>[];

  @override
  Future<({List<Album> items, bool hasMore})> myAlbums([
    int page = 0,
    int size = 20,
  ]) async {
    albumReads++;
    return (items: <Album>[], hasMore: false);
  }

  @override
  Future<({List<PlayList> items, bool hasMore})> myPlayLists(
    bool created, [
    int page = 0,
    int size = 20,
  ]) async {
    playlistReads++;
    return (items: <PlayList>[], hasMore: false);
  }

  @override
  Future<void> favoriteAlbum(Album album, bool value) async {
    await gate?.future;
    album.favorited = value;
  }

  @override
  Future<void> createPlayList(String name) async {
    created.add(name);
    await gate?.future;
  }

  @override
  Future<void> deletePlayList(PlayList playlist) async => await gate?.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  late LibraryController library;
  late LibraryApi a, b;
  setUp(() async {
    final directory = await Directory.systemTemp.createTemp(
      'mixmusic-library-',
    );
    addTearDown(() => directory.delete(recursive: true));
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    await plugins.restored;
    a = LibraryApi(plugins.manager, 'a');
    b = LibraryApi(plugins.manager, 'b');
    plugins.builtins.addAll({'a': a, 'b': b});
    library = LibraryController(plugins);
    addTearDown(plugins.disposeController);
    addTearDown(library.disposeController);
    library.source.value = 'a';
  });

  test('favorite completion invalidates its source without refreshing another source', () async {
    await library.selectSection(LibrarySection.albums);
    a.gate = Completer<void>();
    final album = Album(pluginId: 'a', id: {'album': 1}, favorited: true);
    final pending = library.favorite(album, false);
    library.source.value = 'b';
    await library.selectSection(LibrarySection.albums);
    a.gate!.complete();
    await pending;
    expect(b.albumReads, 1);
    expect(library.source.value, 'b');
    expect(album.favorited, false);
    library.source.value = 'a';
    await library.selectSection(LibrarySection.albums);
    expect(a.albumReads, 2);
  });

  test(
    'creating a playlist does not redirect a newly selected source',
    () async {
      await library.selectSection(LibrarySection.albums);
      a.gate = Completer<void>();
      final pending = library.createPlayList('测试');
      library.source.value = 'b';
      await library.selectSection(LibrarySection.albums);
      a.gate!.complete();
      await pending;
      expect(a.created, ['测试']);
      expect(b.created, isEmpty);
      expect(library.source.value, 'b');
      expect(library.section.value, LibrarySection.albums);
    },
  );

  test('deleting a playlist does not refresh another category', () async {
    await library.selectSection(LibrarySection.created);
    a.gate = Completer<void>();
    final pending = library.deletePlayList(PlayList(pluginId: 'a', id: 1));
    await library.selectSection(LibrarySection.albums);
    a.gate!.complete();
    await pending;
    expect(a.albumReads, 1);
    expect(library.section.value, LibrarySection.albums);
    await library.selectSection(LibrarySection.created);
    expect(a.playlistReads, 2);
  });
}
