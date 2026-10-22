import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/music_collection.dart';
import '../../common/plugin/collection_controller.dart';
import '../../common/plugin/plugin_controller.dart';

class RecommendController extends LxController {
  RecommendController(this.plugins);
  final PluginController plugins;
  late final source = own(''.obs);
  late final current = own(Rx<CollectionController?>(null));

  List<JsExtensionManagerEntry> get sources => plugins.extensions.value
      .where(
        (entry) =>
            entry.state == JsExtensionManagerState.enabled &&
            (entry.installed?.extension.service?.publicExports.contains(
                  'recommendInfo',
                ) ??
                false),
      )
      .toList();

  Future<void> initializeSource() async {
    await plugins.restored;
    if (isDisposed || sources.isEmpty) return;
    final id = plugins.selectedId.value;
    await selectSource(
      sources.any((entry) => entry.id == id) ? id : sources.first.id,
    );
  }

  Future<void> selectSource(String id) async {
    source.value = id;
    final collection = plugins.collection(
      CollectionKind.recommend,
      MusicCollection(pluginId: id, id: 'daily', title: '每日推荐'),
    );
    current.value = collection;
    if (collection.page == 0) await collection.loadMore();
  }

  Future<void> refresh() async => current.value?.refresh();
}
