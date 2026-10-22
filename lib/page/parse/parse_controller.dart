import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/play_list.dart';
import '../../common/plugin/plugin_controller.dart';

class ParseController extends LxController {
  ParseController(this.plugins) {
    result.data([]);
  }
  final PluginController plugins;
  late final result = own(RxAsync<List<PlayList>>());

  List<JsExtensionManagerEntry> get sources => plugins.extensions.value
      .where(
        (entry) =>
            entry.state == JsExtensionManagerState.enabled &&
            (entry.installed?.extension.service?.publicExports.contains(
                  'parsePlayList',
                ) ??
                false),
      )
      .toList();

  Future<void> parse(String text) async {
    if (result.isLoading) return;
    final value = text.trim();
    if (value.isEmpty) {
      result.error(StateError('请输入歌单链接或分享内容'), StackTrace.current);
      return;
    }
    result.loading();
    await plugins.restored;
    if (isDisposed) return;
    final parsers = sources;
    if (parsers.isEmpty) {
      result.error(StateError('没有支持歌单解析的插件'), StackTrace.current);
      return;
    }
    final items = <PlayList>[];
    final errors = <String>[];
    for (final entry in parsers) {
      try {
        final item = await plugins.music(entry.id).parsePlayList(value);
        if (item != null) items.add(item);
      } catch (error, stack) {
        errors.add('${entry.record.name}：$error');
        plugins.addLog(entry.id, 'error', '歌单解析失败：$error\n$stack');
      }
      if (isDisposed) return;
    }
    if (items.isEmpty && errors.isNotEmpty) {
      result.error(StateError(errors.join('\n')), StackTrace.current);
    } else {
      result.data(items);
    }
  }
}
