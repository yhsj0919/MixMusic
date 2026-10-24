import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/local/local_files.dart';
import 'package:mix_music/common/local/local_music_api.dart';
import 'package:mix_music/common/local/local_music_controller.dart';
import 'package:mix_music/common/download/download_files.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class PendingFiles extends LocalFiles {
  final pending = <String, Completer<List<LocalEntry>>>{};
  final released = <String>[];
  @override
  Future<List<LocalEntry>> list(String uri) =>
      (pending[uri] = Completer<List<LocalEntry>>()).future;
  @override
  Future<void> release(String uri) async {
    released.add(uri);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('mixmusic-local-');
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'picked SAF directories retain permissions before returning or saving',
    () async {
      final previous = FilePickerPlatform.instance;
      final picker = FilePickerAndroid();
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = previous);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const uri = 'content://provider/tree/primary%3AMixMusic';
      messenger.setMockMethodCallHandler(
        picker.methodChannel,
        (call) async => uri,
      );
      var reject = false;
      final grants = <bool>[];
      messenger.setMockMethodCallHandler(LocalFiles.channel, (call) async {
        expect(call.method, 'retainDirectory');
        expect(call.arguments['uri'], uri);
        if (reject) {
          throw PlatformException(
            code: 'directory_operation_failed',
            message: '授权失败',
          );
        }
        grants.add(call.arguments['write'] as bool);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(picker.methodChannel, null);
        messenger.setMockMethodCallHandler(LocalFiles.channel, null);
      });
      expect(await LocalFiles().pickDirectory(), uri);
      expect(await DownloadFiles().pickDirectory(), uri);
      expect(grants, [false, true]);
      reject = true;
      final local = LocalMusicController(
        configFile: File('${root.path}/dirs.json'),
      );
      addTearDown(local.disposeController);
      await expectLater(() async {
        final picked = await local.files.pickDirectory();
        if (picked != null) await local.addDirectory(picked);
      }, throwsA(isA<PlatformException>()));
      expect(local.directories.value, isEmpty);
    },
  );

  test(
    'multiple directories persist, normalize duplicates and never delete audio',
    () async {
      final music = await Directory('${root.path}/音乐 A').create();
      final second = await Directory('${root.path}/音乐 B').create();
      final audio = await File('${music.path}/test.wav')
          .writeAsBytes([1, 2, 3]);
      final config = File('${root.path}/config/dirs.json');
      final local = LocalMusicController(configFile: config);
      await Future.wait([
        local.addDirectory(music.path),
        local.addDirectory(second.path),
      ]);
      await local.addDirectory(music.uri.toString());
      expect(local.directories.value.length, 2);
      expect(jsonDecode(await config.readAsString()), local.directories.value);
      await local.disposeController();
      final restored = LocalMusicController(configFile: config);
      addTearDown(restored.disposeController);
      await restored.restored;
      expect(restored.directories.value, [
        music.uri.toString(),
        second.uri.toString(),
      ]);
      await restored.removeDirectory(music.uri.toString());
      expect(await audio.exists(), isTrue);
      expect(restored.directories.value, [second.uri.toString()]);
    },
  );

  test(
    'directory listing is shallow, filters audio and keeps special file names',
    () async {
      final folder = await Directory('${root.path}/sub').create();
      await File('${folder.path}/nested.mp3').writeAsBytes([]);
      await File('${root.path}/歌曲 #1%.FLAC').writeAsBytes([]);
      await File('${root.path}/notes.txt').writeAsBytes([]);
      final files = LocalFiles();
      final entries = await files.list(root.uri.toString());
      expect(entries.map((entry) => entry.name), ['sub', '歌曲 #1%.FLAC']);
      expect(entries.first.directory, isTrue);
      expect(
        File.fromUri(Uri.parse(entries.last.uri)).path,
        '${root.path}${Platform.pathSeparator}歌曲 #1%.FLAC',
      );
    },
  );

  test(
    'SAF content URIs are opaque and channel rows use the same audio filter',
    () async {
      const uri = 'content://provider/tree/primary%3AMusic';
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(LocalFiles.channel, (call) async {
        expect(call.method, 'listDirectory');
        expect(call.arguments, {'uri': uri});
        return [
          {'uri': '$uri/folder', 'name': '专辑', 'directory': true},
          {'uri': '$uri/audio', 'name': 'track.opus', 'directory': false},
          {'uri': '$uri/text', 'name': 'notes.txt', 'directory': false},
        ];
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(LocalFiles.channel, null),
      );
      expect(LocalFiles.normalize(uri), uri);
      final entries = await LocalFiles().list(uri);
      expect(entries.length, 2);
      expect(entries[1].uri, '$uri/audio');
    },
  );

  test(
    'late listings and revoked directories do not replace the active folder',
    () async {
      final files = PendingFiles();
      final local = LocalMusicController(
        configFile: File('${root.path}/dirs.json'),
        files: files,
      );
      addTearDown(local.disposeController);
      await local.addDirectory('content://provider/tree/root');
      final first = local.openDirectory('first');
      final second = local.openDirectory('second');
      files.pending['second']!.complete([
        LocalEntry('file:///new.mp3', 'new.mp3', false),
      ]);
      await second;
      files.pending['first']!.complete([]);
      await first;
      expect(local.entries.value!.single.name, 'new.mp3');
      final third = local.openDirectory('third');
      await local.removeDirectory('content://provider/tree/root');
      files.pending['third']!.complete([LocalEntry('old', 'old.mp3', false)]);
      await third;
      expect(local.entries.value, isEmpty);
      expect(local.selected.value, isEmpty);
      expect(files.released, ['content://provider/tree/root']);
    },
  );

  test('local source returns file/content URIs and metadata through the common API', () async {
    final plugins = PluginController();
    addTearDown(plugins.disposeController);
    final local = LocalMusicController(
      configFile: File('${root.path}/dirs.json'),
    );
    addTearDown(local.disposeController);
    final api = LocalMusicApi(plugins.manager);
    plugins.builtins[LocalMusicController.pluginId] = api;
    expect(plugins.music(LocalMusicController.pluginId), same(api));
    final file = await File('${root.path}/test.wav').writeAsBytes([]);
    final song = local.song(LocalEntry(file.uri.toString(), 'test.wav', false));
    expect((await api.playUrl(song)).url, file.uri.toString());
    final tagged = api.updateMetadata(song, {
      'TITLE': '歌曲',
      'ARTIST': '歌手',
      'ALBUM': '专辑',
    });
    expect(tagged.title, '歌曲');
    expect(tagged.subtitle, '歌手');
    expect(tagged.details['albumName'], '专辑');
    expect(tagged.id, song.id);
    expect(
      MusicApi(plugins.manager, 'test').updateMetadata(song, {'title': '不要覆盖'}),
      same(song),
    );
    final content = local.song(
      LocalEntry('content://provider/document/audio', 'audio.mp3', false),
    );
    expect((await api.playUrl(content)).url, content.id);
    await file.delete();
    await expectLater(api.playUrl(song), throwsStateError);
  });
}
