import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/rank.dart';
import '../../common/plugin/plugin_controller.dart';

class RankController extends LxController {
  RankController(this.plugins);
  final PluginController plugins;
  late final source = own(''.obs);
  late final ranks = own(RxAsync<List<Rank>>());
  int _request = 0;

  List<JsExtensionManagerEntry> get sources => plugins.extensions.value
      .where(
        (entry) =>
            entry.state == JsExtensionManagerState.enabled &&
            (entry.installed?.extension.service?.publicExports.contains(
                  'rankList',
                ) ??
                false),
      )
      .toList();

  Future<void> initializeSource() async {
    await plugins.restored;
    if (isDisposed || sources.isEmpty) return;
    final selected = plugins.selectedId.value;
    final id = sources.any((entry) => entry.id == selected)
        ? selected
        : sources.first.id;
    final cached = plugins.selectedId.value == id
        ? plugins.sections.value['ranks']
        : null;
    if (cached != null) {
      source.value = id;
      ranks.data(cached.cast<Rank>());
    } else {
      await load(id);
    }
  }

  Future<void> load(String pluginId) async {
    final request = ++_request;
    source.value = pluginId;
    ranks.loading();
    try {
      final result = await plugins.music(pluginId).rankList();
      if (isDisposed || request != _request) return;
      ranks.data(result);
    } catch (error, stack) {
      if (isDisposed || request != _request) return;
      ranks.error(error, stack);
      plugins.addLog(pluginId, 'error', '排行榜加载失败：$error\n$stack');
    }
  }
}
