import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../local/local_files.dart';

class DownloadFiles {
  static String folderName(String name) => name
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .trim()
      .replaceAll(RegExp(r'[. ]+$'), '');

  Future<String> createFolder(String directory, String name) async {
    if (directory.startsWith('content:')) {
      return (await LocalFiles.channel.invokeMethod<String>(
        'createDownloadFolder',
        {'uri': directory, 'name': name},
      ))!;
    }
    return (await Directory('$directory/$name').create()).path;
  }

  Future<void> checkDirectory(String directory) async {
    if (directory.startsWith('content:')) {
      await LocalFiles.channel.invokeMethod<void>('checkDownloadDirectory', {
        'uri': directory,
      });
    }
  }

  static const extensions = ['mp3', 'flac', 'm4a', 'aac', 'ogg', 'wav', 'opus'];

  Future<({String path, int bytes})?> find(String directory, String key) async {
    final suffixes = extensions.map((ext) => '-${key.substring(0, 12)}.$ext');
    if (directory.startsWith('content:')) {
      final entries = await LocalFiles.channel.invokeListMethod<dynamic>(
        'listDirectory',
        {'uri': directory},
      );
      for (final entry in entries!) {
        if (entry['directory'] == false &&
            suffixes.any(
              (suffix) => (entry['name'] as String).endsWith(suffix),
            ) &&
            (entry['size'] as int) > 0) {
          return (path: entry['uri'] as String, bytes: entry['size'] as int);
        }
      }
    } else {
      await for (final entry in Directory(directory).list()) {
        if (entry is! File || !suffixes.any(entry.path.endsWith)) continue;
        final bytes = await entry.length();
        if (bytes > 0) return (path: entry.path, bytes: bytes);
      }
    }
    return null;
  }

  Future<String?> pickDirectory() => FilePicker.getDirectoryPath(
    androidOptions: const FilePickerAndroidOptions(
      safOptions: AndroidSAFOptions(
        grant: AndroidSAFGrant.lifetime,
        accessMode: AndroidSAFAccessMode.readWrite,
      ),
    ),
  );

  Future<String> save(
    File file,
    String directory,
    String name,
    String mime,
  ) async {
    if (directory.startsWith('content:')) {
      return (await LocalFiles.channel.invokeMethod<String>('saveDownload', {
        'uri': directory,
        'path': file.path,
        'name': name,
        'mime': mime,
      }))!;
    }
    final target = File('$directory/$name');
    if (await target.exists()) throw StateError('目标文件已存在');
    return (await file.rename(target.path)).path;
  }
}
