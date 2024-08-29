import 'dart:convert';
import 'dart:io';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:path/path.dart';

///获取所有插件
Future<List<PluginsInfo>> getSystemPlugins({required String rootDir}) async {
  var dir = Directory(rootDir);
  final plugins = <PluginsInfo>[];
  var list = <FileSystemEntity>[];
  try {
    list = dir.listSync();
  } catch (e) {
    debugPrint("插件目录不存在:$e");
  }

  for (final ext in list) {
    if (ext.path.endsWith(".js")) {
      if (kDebugMode) {
        print(basename(ext.path));
      }
      var file = File(ext.path);
      final content = await file.readAsString();

      var info = _parseExtension(content);

      if (info?.name?.isNotEmpty == true) {
        info!.path = ext.path;
        plugins.add(info);
      }
    }
  }
  return plugins;
}

///解析插件
PluginsInfo? _parseExtension(String extension) {
  Map<String, dynamic> result = {};
  RegExp reg = RegExp(r'@(\w+)\s+(.*)');
  Iterable<RegExpMatch> matches = reg.allMatches(extension);
  for (RegExpMatch match in matches) {
    result[match.group(1)!] = match.group(2);
  }
  try {
    result["method"] = json.decode(result["method"]);
  } catch (e) {
    result["method"] = [];
  }
  return JsonMapper.deserialize<PluginsInfo>(json.encode(result));
}

///js扩展
extension JavascriptRuntimeFetchExtension on JavascriptRuntime {
  ///启用axios
  Future<JavascriptRuntime> enableAxios() async {
    String axios = await rootBundle.loadString("assets/axios.js");
    final evalFetchResult = evaluate(axios);
    if (kDebugMode) {
      print('Axios 结果: $evalFetchResult');
    }
    return this;
  }

  ///启用sleep
  Future<JavascriptRuntime> enableSleep() async {
    String sleep = await rootBundle.loadString("assets/sleep.js");
    final evalFetchResult = evaluate(sleep);
    if (kDebugMode) {
      print('sleep 结果: $evalFetchResult');
    }
    return this;
  }

  /// 启用加密
  Future<JavascriptRuntime> enableCrypto() async {
    String crypto = await rootBundle.loadString("assets/crypto.js");
    final evalFetchResult = evaluate(crypto);
    if (kDebugMode) {
      print('crypto 结果: $evalFetchResult');
    }
    return this;
  }
}
