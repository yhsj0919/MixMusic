import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class LocalEntry {
  LocalEntry(this.uri, this.name, this.directory);
  final String uri;
  final String name;
  final bool directory;
}

class LocalFiles {
  static const channel = MethodChannel('mixmusic/local_files');
  static const extensions = {
    'mp3',
    'flac',
    'wav',
    'm4a',
    'aac',
    'ogg',
    'opus',
    'wma',
    'aiff',
    'aif',
    'ape',
    'alac',
  };

  static String normalize(String path) => path.startsWith('content:')
      ? path
      : (path.startsWith('file:')
                ? Directory.fromUri(Uri.parse(path))
                : Directory(path))
            .absolute
            .uri
            .normalizePath()
            .toString();

  static String name(String uri) {
    final segment = Uri.parse(uri).pathSegments
        .where((part) => part.isNotEmpty)
        .last;
    final title = segment.split(':').last;
    return title.isEmpty ? segment : title;
  }

  Future<String?> pickDirectory() => FilePicker.getDirectoryPath(
    androidOptions: const FilePickerAndroidOptions(
      safOptions: AndroidSAFOptions(grant: AndroidSAFGrant.lifetime),
    ),
  );

  Future<List<LocalEntry>> list(String uri) async {
    final entries = <LocalEntry>[];
    if (uri.startsWith('content:')) {
      final result = await channel.invokeListMethod<Map>('listDirectory', {
        'uri': uri,
      });
      for (final item in result!) {
        entries.add(
          LocalEntry(
            item['uri'] as String,
            item['name'] as String,
            item['directory'] as bool,
          ),
        );
      }
    } else {
      await for (final item in Directory.fromUri(
        Uri.parse(uri),
      ).list(followLinks: false)) {
        if (item is File || item is Directory) {
          entries.add(
            LocalEntry(
              item.uri.toString(),
              name(item.uri.toString()),
              item is Directory,
            ),
          );
        }
      }
    }
    entries.removeWhere(
      (item) =>
          !item.directory &&
          !extensions.contains(item.name.split('.').last.toLowerCase()),
    );
    entries.sort(
      (a, b) => a.directory != b.directory
          ? (a.directory ? -1 : 1)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return entries;
  }

  Future<void> release(String uri) async {
    if (uri.startsWith('content:')) {
      await AndroidSAFHandle(
        accessMode: AndroidSAFAccessMode.readOnly,
        uri: Uri.parse(uri),
      ).releaseGrant();
    }
  }
}
