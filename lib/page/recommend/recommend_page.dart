import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';
import '../playlist/play_list_detail_page.dart';
import '../setting/extension/plugin_logs.dart';
import 'recommend_controller.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, required this.plugins});
  final PluginController plugins;

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  late final controller = RecommendController(widget.plugins);
  late final ready = controller.initializeSource();

  @override
  void initState() {
    super.initState();
    ready;
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: const HyperText('每日推荐'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
      actions: [
        HyperIconButton.ghost(
          tooltip: '刷新',
          icon: const HyperIcon(Icons.refresh),
          onPressed: controller.refresh,
        ),
        HyperIconButton.ghost(
          tooltip: '插件日志',
          icon: const HyperIcon(Icons.receipt_long_outlined),
          onPressed: () =>
              showPluginLogs(context, pluginId: controller.source.value),
        ),
      ],
    ),
    body: FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return HyperResult.empty(
            title: '初始化失败',
            description: '${snapshot.error}',
          );
        }
        return Obx(() {
          final sources = controller.sources;
          final collection = controller.current.value;
          if (sources.isEmpty) {
            return const HyperResult.empty(title: '没有支持每日推荐的插件');
          }
          return Column(
            children: [
              DefaultTabController(
                key: ValueKey(controller.source.value),
                length: sources.length,
                initialIndex: sources
                    .indexWhere((entry) => entry.id == controller.source.value)
                    .clamp(0, sources.length - 1),
                child: HyperTabBar.separated(
                  isScrollable: true,
                  tabs: [
                    for (final entry in sources)
                      HyperTab(text: entry.record.name),
                  ],
                  onTap: (index) => controller.selectSource(sources[index].id),
                ),
              ),
              if (collection != null)
                Expanded(
                  child: PlayListDetailPage(
                    key: ValueKey(collection),
                    collection: collection,
                    embedded: true,
                  ),
                ),
            ],
          );
        });
      },
    ),
  );
}
