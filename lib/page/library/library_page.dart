import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/music_resource.dart';
import '../../common/entity/play_list.dart';
import '../../common/plugin/plugin_controller.dart';
import '../playlist/play_list_detail_page.dart';
import '../setting/extension/plugin_logs.dart';
import 'library_controller.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.plugins});
  final PluginController plugins;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final controller = LibraryController(widget.plugins);
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

  Future<void> create() async {
    final input = TextEditingController();
    final name = await showHyperDialog<String>(
      context: context,
      builder: (context) => HyperDialog(
        title: const HyperText('创建歌单'),
        content: HyperTextField(controller: input, hintText: '歌单名称'),
        actions: [
          HyperButton.text(
            onPressed: () => context.pop(),
            label: const HyperText('取消'),
          ),
          HyperButton.filled(
            onPressed: () => context.pop(input.text),
            label: const HyperText('创建'),
          ),
        ],
      ),
    );
    input.dispose();
    if (name == null || name.trim().isEmpty) return;
    await widget.plugins.manage(controller.source.value, () async {
      await controller.createPlayList(name);
      return '歌单已创建';
    });
  }

  Future<void> remove(MusicResource item) async {
    final created = controller.section.value == LibrarySection.created;
    final confirmed = await showHyperDialog<bool>(
      context: context,
      builder: (context) => HyperDialog(
        title: HyperText(created ? '删除歌单' : '取消收藏'),
        content: HyperText(item.title),
        actions: [
          HyperButton.text(
            onPressed: () => context.pop(false),
            label: const HyperText('取消'),
          ),
          HyperButton.filled(
            onPressed: () => context.pop(true),
            label: const HyperText('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.plugins.manage(item.pluginId, () async {
      if (created) {
        await controller.deletePlayList(item as PlayList);
      } else {
        await controller.favorite(item, false);
      }
      return created ? '歌单已删除' : '已取消收藏';
    });
  }

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: const HyperText('我的'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
      actions: [
        HyperButton.text(
          onPressed: () {
            context.push('/history');
          },
          label: const HyperText('播放历史'),
        ),
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
      builder: (context, snapshot) => Obx(() {
        final sources = controller.sources;
        if (snapshot.hasError) {
          return HyperResult.empty(
            title: '初始化失败',
            description: '${snapshot.error}',
          );
        }
        if (sources.isEmpty) {
          return const HyperResult.empty(title: '没有支持“我的”的插件');
        }
        final sections = controller.sections;
        if (sections.isEmpty) return const Center(child: HyperText('正在加载…'));
        final data = controller.state.value;
        final selected = controller.section.value;
        final account = widget.plugins.accounts.value[controller.source.value];
        return Column(
          children: [
            DefaultTabController(
              key: ValueKey(controller.source.value),
              length: sources.length,
              initialIndex: sources
                  .indexWhere((x) => x.id == controller.source.value)
                  .clamp(0, sources.length - 1),
              child: HyperTabBar.separated(
                isScrollable: true,
                tabs: [
                  for (final item in sources) HyperTab(text: item.record.name),
                ],
                onTap: (index) => controller.selectSource(sources[index].id),
              ),
            ),
            if (account != null)
              HyperListTile(
                title: HyperText(
                  account.status == 'signedIn' ? account.name : account.message,
                ),
                trailing: HyperButton.text(
                  label: const HyperText('账号管理'),
                  onPressed: () => context.push('/settings/extensions'),
                ),
              ),
            DefaultTabController(
              key: ValueKey((controller.source.value, selected)),
              length: sections.length,
              initialIndex: sections
                  .indexOf(selected)
                  .clamp(0, sections.length - 1),
              child: HyperTabBar.underline(
                isScrollable: true,
                tabs: [for (final item in sections) HyperTab(text: item.title)],
                onTap: (index) => controller.selectSection(sections[index]),
              ),
            ),
            if (widget.plugins.action.hasError)
              HyperText('操作失败：${widget.plugins.action.errorValue}'),
            if (selected == LibrarySection.created &&
                controller.supports('createPlayList'))
              HyperButton.text(
                onPressed: create,
                label: const HyperText('创建歌单'),
              ),
            if (selected == LibrarySection.liked &&
                controller.liked.value != null)
              Expanded(
                child: PlayListDetailPage(
                  key: ValueKey(controller.liked.value),
                  collection: controller.liked.value!,
                  embedded: true,
                ),
              )
            else
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (event) {
                    if (event.depth == 0 &&
                        event.metrics.extentAfter < 240 &&
                        data.error.isEmpty) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView(
                    children: [
                      for (final item in data.items)
                        HyperListTile(
                          leading: item.cover == null || item.cover!.isEmpty
                              ? const HyperIcon(Icons.library_music_outlined)
                              : Image.network(
                                  item.cover!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const HyperIcon(
                                    Icons.library_music_outlined,
                                  ),
                                ),
                          title: Row(
                            children: [
                              Flexible(child: HyperText(item.title)),
                              if (item.favorited != null) ...[
                                const SizedBox(width: 8),
                                HyperBadge(
                                  label: item.favorited! ? '已收藏' : '未收藏',
                                ),
                              ],
                            ],
                          ),
                          subtitle: HyperText(item.subtitle ?? ''),
                          onTap: () =>
                              context.push(selected.route, extra: item),
                          trailing:
                              controller.supports(switch (selected) {
                                LibrarySection.created => 'deletePlayList',
                                LibrarySection.playlists => 'favoritePlayList',
                                LibrarySection.albums => 'favoriteAlbum',
                                LibrarySection.videos => 'favoriteMv',
                                LibrarySection.artists => 'favoriteArtist',
                                LibrarySection.liked => '',
                              })
                              ? HyperMenuButton(
                                  items: [
                                    HyperMenuItem(
                                      id: 'remove',
                                      label: selected == LibrarySection.created
                                          ? '删除歌单'
                                          : '取消收藏',
                                    ),
                                  ],
                                  onSelected: (_) => remove(item),
                                  child: const HyperIcon(Icons.more_horiz),
                                )
                              : null,
                        ),
                      if (data.loading) const Center(child: HyperText('正在加载…')),
                      if (data.error.isNotEmpty) ...[
                        HyperText('加载失败：${data.error}'),
                        HyperButton.text(
                          onPressed: controller.loadMore,
                          label: const HyperText('重试'),
                        ),
                      ],
                      if (data.items.isEmpty &&
                          !data.loading &&
                          data.error.isEmpty)
                        const HyperResult.empty(title: '暂无内容'),
                      if (data.hasMore && !data.loading && data.error.isEmpty)
                        HyperButton.text(
                          onPressed: controller.loadMore,
                          label: const HyperText('加载更多'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    ),
  );
}
