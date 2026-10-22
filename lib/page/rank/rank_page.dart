import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';
import '../../common/entity/rank.dart';
import '../setting/extension/plugin_logs.dart';
import 'rank_controller.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key, required this.plugins});
  final PluginController plugins;
  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  late final controller = RankController(widget.plugins);
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
      title: const HyperText('排行榜'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
    ),
    body: FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return HyperResult.empty(
            title: '插件恢复失败',
            description: '${snapshot.error}',
          );
        }
        return Obx(() {
          final sources = controller.sources;
          if (sources.isEmpty) {
            return const HyperResult.empty(title: '没有支持排行榜的音源');
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
                  onTap: (index) => controller.load(sources[index].id),
                ),
              ),
              Expanded(
                child: controller.ranks.when(
                  loading: () => const Center(child: HyperText('正在加载…')),
                  error: (error, stack) => HyperResult.empty(
                    title: '排行榜加载失败',
                    description: '$error',
                    actions: [
                      HyperButton.text(
                        onPressed: () =>
                            controller.load(controller.source.value),
                        label: const HyperText('重试'),
                      ),
                      HyperButton.text(
                        onPressed: () => showPluginLogs(
                          context,
                          pluginId: controller.source.value,
                        ),
                        label: const HyperText('查看插件日志'),
                      ),
                    ],
                  ),
                  data: (ranks) => ranks.isEmpty
                      ? const HyperResult.empty(title: '暂无排行榜')
                      : CustomScrollView(
                          slivers: [
                            for (final group in ranks.where(
                              (rank) => rank.isGroup,
                            ))
                              _group(context, group),
                            if (ranks.any((rank) => !rank.isGroup))
                              _grid(
                                context,
                                ranks.where((rank) => !rank.isGroup).toList(),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          );
        });
      },
    ),
  );

  Widget _group(BuildContext context, Rank group) => SliverMainAxisGroup(
    slivers: [
      PinnedHeaderSliver(
        child: HyperCard(
          style: HyperCardStyle(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
          child: HyperText(group.title, variant: HyperTextVariant.sectionTitle),
        ),
      ),
      if (group.ranks.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(padding: EdgeInsets.all(16), child: HyperText('暂无榜单')),
        ),
      if (group.ranks.any((rank) => !rank.isGroup))
        _grid(context, group.ranks.where((rank) => !rank.isGroup).toList()),
      for (final child in group.ranks.where((rank) => rank.isGroup))
        _group(context, child),
    ],
  );

  Widget _grid(BuildContext context, List<Rank> ranks) {
    final desktop = HyperDeviceDetector.of(context) == HyperDeviceType.desktop;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: desktop ? 160 : 150,
          childAspectRatio: desktop ? 160 / 182 : 1,
          crossAxisSpacing: desktop ? 4 : 16,
          mainAxisSpacing: desktop ? 8 : 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final rank = ranks[index];
          return HyperCard(
            style: HyperCardStyle(
              background: const HyperFill.none(),
              padding: const EdgeInsets.all(4),
              border: Border.all(color: Colors.transparent),
              boxShadow: const [],
            ),
            onTap: () => context.push('/rank', extra: rank),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: rank.cover == null || rank.cover!.isEmpty
                          ? const Center(
                              child: HyperIcon(Icons.leaderboard_outlined),
                            )
                          : Image.network(
                              rank.cover!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stack) => const Center(
                                child: HyperIcon(Icons.leaderboard_outlined),
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 22,
                  child: HyperText(
                    rank.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }, childCount: ranks.length),
      ),
    );
  }
}
