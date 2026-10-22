import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_music/common/download/download_files.dart';
import 'package:mix_music/common/local/local_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('folder names cannot escape the root directory', () {
    expect(DownloadFiles.folderName('../甲/乙:* '), '.._甲_乙__');
    expect(DownloadFiles.folderName('..'), '');
    expect(DownloadFiles.folderName('   '), '');
  });

  test('Android subfolder creation passes the root URI and name', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(LocalFiles.channel, (call) async {
      expect(call.method, 'createDownloadFolder');
      expect(call.arguments, {
        'uri': 'content://test/tree/music',
        'name': '歌手',
      });
      return 'content://test/tree/music/document/artist';
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(LocalFiles.channel, null),
    );
    expect(
      await DownloadFiles().createFolder('content://test/tree/music', '歌手'),
      'content://test/tree/music/document/artist',
    );
  });
  test(
    'only nonempty final audio names match the resource and quality',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'download-files-',
      );
      addTearDown(() => directory.delete(recursive: true));
      const key = '123456789012abcdef';
      final files = DownloadFiles();
      await File('${directory.path}/song-123456789012.part').writeAsBytes([1]);
      await File('${directory.path}/song-123456789012.mp3').writeAsBytes([]);
      await File('${directory.path}/song-000000000000.mp3').writeAsBytes([1]);
      expect(await files.find(directory.path, key), isNull);
      final complete = File('${directory.path}/renamed-123456789012.flac');
      await complete.writeAsBytes([1, 2, 3]);
      final found = await files.find(directory.path, key);
      expect(File(found!.path).uri, complete.uri);
      expect(found.bytes, 3);
    },
  );

  test('Android lookup ignores partial documents', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(LocalFiles.channel, (call) async {
      expect(call.method, 'listDirectory');
      return [
        {
          'name': 'song-123456789012.mp3.part',
          'uri': 'partial',
          'directory': false,
          'size': 9,
        },
        {
          'name': 'song-123456789012.mp3',
          'uri': 'complete',
          'directory': false,
          'size': 12,
        },
      ];
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(LocalFiles.channel, null),
    );
    final found = await DownloadFiles().find(
      'content://test/tree/music',
      '123456789012abcdef',
    );
    expect(found?.path, 'complete');
    expect(found?.bytes, 12);
  });

  test('authorized Android directory uses native writer, not File', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(LocalFiles.channel, (call) async {
      expect(call.method, 'saveDownload');
      expect(call.arguments, {
        'uri': 'content://test/tree/music',
        'path': 'test.part',
        'name': 'song.mp3',
        'mime': 'audio/mpeg',
      });
      return 'content://test/document/song';
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(LocalFiles.channel, null),
    );
    expect(
      await DownloadFiles().save(
        File('test.part'),
        'content://test/tree/music',
        'song.mp3',
        'audio/mpeg',
      ),
      'content://test/document/song',
    );
  });
}
