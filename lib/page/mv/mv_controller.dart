import 'package:flutter/foundation.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';
import '../../common/entity/mv.dart';

class MvController extends LxController {
  MvController(this.plugins, this.resource);
  final PluginController plugins;
  final Mv resource;
  late final info = own(RxAsync<Mv>());
  int _request = 0;

  bool get supportsFavorite =>
      plugins.manager
          .find(resource.pluginId)
          ?.installed
          ?.extension
          .service
          ?.publicExports
          .contains('favoriteMv') ??
      false;

  Future<void> favorite(bool value) async {
    await plugins.music(resource.pluginId).favoriteMv(resource, value);
    resource.favorited = value;
    if (isDisposed || !info.hasData) return;
    info.value!.favorited = value;
    info.data(info.value!);
  }

  Future<void> load() async {
    final request = ++_request;
    final id = resource.pluginId;
    info.loading();
    try {
      final result = await plugins.music(id).mvInfo(resource);
      if (isDisposed || request != _request) return;
      info.data(result);
      printAddresses();
    } catch (error, stack) {
      if (isDisposed || request != _request) return;
      info.error(error, stack);
      plugins.addLog(id, 'error', 'MV 详情加载失败：$error\n$stack');
    }
  }

  void printAddresses() {
    final detail = info.value;
    if (detail == null) return;
    final addresses = <String>[
      if (detail.url != null && detail.url!.isNotEmpty) 'MV 地址：${detail.url}',
      for (final quality in detail.qualities)
        if (quality.url != null && quality.url!.isNotEmpty)
          'MV ${quality.title} 地址：${quality.url}',
    ];
    if (addresses.isEmpty) addresses.add('MV 未返回地址');
    for (final message in addresses) {
      debugPrint(message);
      plugins.addLog(resource.pluginId, 'log', message);
    }
  }
}
