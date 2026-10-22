import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';
import 'music_list_controller.dart';

class MusicListPage extends StatefulWidget {
  const MusicListPage({super.key, required this.plugins, required this.kind});
  final PluginController plugins;
  final MusicListKind kind;
  @override
  State<MusicListPage> createState() => _MusicListPageState();
}

class _MusicListPageState extends State<MusicListPage> {
  late final controller = MusicListController(widget.plugins, widget.kind);
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
      title: HyperText(widget.kind.title),
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
          onPressed: controller.refreshList,
        ),
      ],
    ),
    body: FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return HyperResult.empty(
            title: '列表初始化失败',
            description: '${snapshot.error}',
          );
        }
        return Obx(() {
          final sources = controller.sources;
          if (sources.isEmpty) {
            return HyperResult.empty(title: '没有支持${widget.kind.title}列表的音源');
          }
          final data = controller.state.value;
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: HyperText(controller.categoryTitle)),
                    if (data.categories.isNotEmpty ||
                        data.categoryError.isNotEmpty)
                      HyperButton.text(
                        onPressed: _categories,
                        label: const HyperText('分类'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (event) {
                    if (event.depth == 0 &&
                        event.metrics.extentAfter < 240 &&
                        event is ScrollUpdateNotification &&
                        data.error.isEmpty) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    slivers: [
                      if (data.items.isEmpty &&
                          !data.loading &&
                          data.error.isEmpty)
                        const SliverToBoxAdapter(
                          child: HyperResult.empty(title: '暂无内容'),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 160 / 200,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 8,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = data.items[index];
                            return HyperCard(
                              style: HyperCardStyle(
                                padding: const EdgeInsets.all(4),
                              ),
                              onTap: () =>
                                  context.push(widget.kind.route, extra: item),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child:
                                            item.cover == null ||
                                                item.cover!.isEmpty
                                            ? const Center(
                                                child: HyperIcon(
                                                  Icons.library_music_outlined,
                                                ),
                                              )
                                            : Image.network(
                                                item.cover!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      _,
                                                      error,
                                                      stack,
                                                    ) => const HyperIcon(
                                                      Icons
                                                          .library_music_outlined,
                                                    ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  HyperText(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  HyperText(
                                    item.subtitle ?? '',
                                    variant: HyperTextVariant.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }, childCount: data.items.length),
                        ),
                      ),
                      if (data.loading)
                        const SliverToBoxAdapter(
                          child: Center(child: HyperText('正在加载…')),
                        ),
                      if (data.error.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              HyperText('加载失败：${data.error}'),
                              HyperButton.text(
                                onPressed: controller.loadMore,
                                label: const HyperText('重试'),
                              ),
                            ],
                          ),
                        ),
                      if (data.hasMore &&
                          !data.loading &&
                          data.error.isEmpty &&
                          data.items.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: HyperButton.text(
                              onPressed: controller.loadMore,
                              label: const HyperText('加载更多'),
                            ),
                          ),
                        ),
                      if (!data.hasMore && data.items.isNotEmpty)
                        const SliverToBoxAdapter(
                          child: Center(child: HyperText('已加载全部')),
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

  Future<void> _categories() async {
    if (controller.state.value.categoryError.isNotEmpty) {
      await controller.loadCategories();
    }
    if (!mounted) return;
    final result =
        await showHyperDialog<({Map<String, dynamic>? value, dynamic group})>(
          context: context,
          builder: (context) => HyperDialog(
            title: const HyperText('分类'),
            content: SizedBox(
              width: 400,
              height: 360,
              child: ListView(
                children: [
                  HyperListTile(
                title: const HyperText('默认'),
                    onTap: () => context.pop((value: null, group: null)),
                  ),
                  if (controller.state.value.categoryError.isNotEmpty)
                    HyperText(controller.state.value.categoryError),
                  for (final category in controller.state.value.categories)
                    ..._category(context, category),
                ],
              ),
            ),
          ),
        );
    if (result != null) {
      await controller.selectCategory(result.value, group: result.group);
    }
  }

  List<Widget> _category(
    BuildContext context,
    Map<String, dynamic> category, {
    dynamic group,
  }) {
    final children = category['subType'] as List? ?? [];
    return [
      HyperListTile(
        title: HyperText(category['title']?.toString() ?? ''),
        onTap: children.isEmpty
            ? () => context.pop((value: category, group: group))
            : null,
      ),
      for (final child in children)
        ..._category(
          context,
          Map<String, dynamic>.from(child as Map),
          group: category['independent'] == true ? category['id'] : group,
        ),
    ];
  }
}
