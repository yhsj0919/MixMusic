import 'package:flutter/material.dart' hide SearchController;
import 'package:go_router/go_router.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';
import '../app_playing/song_actions.dart';
import '../setting/extension/plugin_logs.dart';
import 'search_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final input = TextEditingController();
  late final plugins = context.lx.find<PluginController>();
  late final controller = SearchController(plugins);

  @override
  void dispose() {
    input.dispose();
    controller.disposeController();
    super.dispose();
  }

  Widget page(
    Widget body, {
    PreferredSizeWidget? bottom,
    ValueChanged<String>? onSearch,
  }) => HyperScaffold(
    appBar: HyperAppBar(
      title: HyperTextField(
        controller: input,
        hintText: '搜索${controller.category.value.title}',
        textInputAction: TextInputAction.search,
        showClearButton: true,
        onSubmitted: onSearch,
      ),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              key: const ValueKey('page-back'),
              tooltip: '返回',
              onPressed: () => context.go('/'),
              icon: const HyperIcon(Icons.arrow_back_rounded),
            ),
      actions: [
        HyperButton.text(
          onPressed: onSearch == null
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  onSearch(input.text);
                },
          label: const HyperText('搜索'),
        ),
      ],
      bottom: bottom,
    ),
    body: body,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: plugins.restored,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return page(
          HyperResult.empty(title: '插件恢复失败', description: '${snapshot.error}'),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return page(const Center(child: HyperText('正在恢复插件…')));
      }
      return Obx(() {
        final sources = plugins.extensions.value
            .where(
              (entry) =>
                  entry.state == JsExtensionManagerState.enabled &&
                  SearchCategory.values.any(
                    (type) =>
                        entry.installed?.extension.service?.publicExports
                            .contains(type.exportName) ??
                        false,
                  ),
            )
            .toList();
        if (sources.isEmpty) {
          return page(
            HyperResult.empty(
              title: '没有可搜索的音源',
              description: '请先安装并启用支持搜索的插件',
              actions: [
                HyperButton.tonal(
                  onPressed: () => context.go('/settings/extensions'),
                  label: const HyperText('插件管理'),
                ),
              ],
            ),
          );
        }
        final selected =
            sources.any((entry) => entry.id == controller.source.value)
            ? controller.source.value
            : sources.any((entry) => entry.id == plugins.selectedId.value)
            ? plugins.selectedId.value
            : sources.first.id;
        final category = controller.category.value;
        final selectedEntry = sources.firstWhere(
          (entry) => entry.id == selected,
        );
        bool supports(JsExtensionManagerEntry entry, SearchCategory type) =>
            entry.installed!.extension.service!.publicExports.contains(
              type.exportName,
            );
        final supported = supports(selectedEntry, category);
        void search(String text, String id, SearchCategory type) {
          final entry = sources.firstWhere((entry) => entry.id == id);
          controller.search(supports(entry, type) ? text : '', id, type: type);
        }

        final sites = DefaultTabController(
          key: ValueKey((sources.map((entry) => entry.id).join(','), selected)),
          length: sources.length,
          initialIndex: sources.indexOf(selectedEntry),
          child: HyperTabBar.separated(
            key: const ValueKey('search-sources'),
            isScrollable: true,
            padding: EdgeInsets.zero,
            tabs: [
              for (final entry in sources) HyperTab(text: entry.record.name),
            ],
            onTap: (index) => search(input.text, sources[index].id, category),
          ),
        );
        final categories = DefaultTabController(
          key: ValueKey(category),
          length: SearchCategory.values.length,
          initialIndex: category.index,
          child: HyperTabBar.underline(
            key: const ValueKey('search-categories'),
            isScrollable: true,
            padding: EdgeInsets.zero,
            tabs: [
              for (final type in SearchCategory.values)
                HyperTab(
                  child: Tooltip(
                    message: supports(selectedEntry, type)
                        ? type.title
                        : '此音源不支持${type.title}搜索',
                    child: HyperText(
                      type.title,
                      style: TextStyle(
                        color: supports(selectedEntry, type)
                            ? null
                            : HyperTheme.of(context).colors.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
            onTap: (index) =>
                search(input.text, selected, SearchCategory.values[index]),
          ),
        );
        final desktop =
            HyperDeviceDetector.of(context) == HyperDeviceType.desktop;
        final count = category == SearchCategory.song
            ? controller.songs.value.length
            : controller.items.value.length;
        final theme = HyperTheme.of(context);
        final textStyle = theme.textTheme.labelLarge?.copyWith(
          fontSize: theme.typography.control,
        );
        final painter = TextPainter(
          text: TextSpan(text: 'Hg', style: textStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final scaledHeight = painter.height;
        painter.textScaler = TextScaler.noScaling;
        painter.layout();
        final tabHeight =
            HyperTheme.sizesOf(context).tabBar.height +
            (scaledHeight - painter.height).clamp(0.0, double.infinity);
        painter.dispose();
        return page(
          NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              if (notification.depth == 0 &&
                  notification.metrics.extentAfter < 240 &&
                  controller.error.value.isEmpty) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              key: ValueKey((
                controller.source.value,
                controller.keyword,
                category,
              )),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: count + 1,
              itemBuilder: (context, index) {
                if (index < count && category == SearchCategory.song) {
                  final song = controller.songs.value[index];
                  return HyperListTile(
                    leading: const HyperIcon(Icons.music_note_rounded),
                    title: Row(
                      children: [
                        Flexible(child: HyperText(song.title)),
                        const SizedBox(width: 8),
                        HyperBadge(
                          label: switch (song.favorited) {
                            true => '已收藏',
                            false => '未收藏',
                            null => '收藏未知',
                          },
                        ),
                        if (song.vip) ...[
                          const SizedBox(width: 8),
                          const HyperBadge(label: 'VIP'),
                        ],
                      ],
                    ),
                    subtitle: HyperText(song.subtitle ?? song.pluginId),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HyperText('${song.qualities.length} 种音质'),
                        HyperIconButton.ghost(
                          tooltip: '歌曲操作',
                          icon: const HyperIcon(Icons.more_horiz),
                          onPressed: () async {
                            await showSongActions(context, song);
                            if (context.mounted) controller.songs.refresh();
                          },
                        ),
                      ],
                    ),
                    onTap: () => selectAndPlay(context, song),
                  );
                }
                if (index < count) {
                  final item = controller.items.value[index];
                  return HyperListTile(
                    leading: HyperIcon(switch (category) {
                      SearchCategory.album => Icons.album_outlined,
                      SearchCategory.artist => Icons.person_outline,
                      SearchCategory.playlist => Icons.queue_music,
                      _ => Icons.music_video_outlined,
                    }),
                    title: HyperText(item.title),
                    subtitle: HyperText(item.subtitle ?? ''),
                    onTap: () => context.push(
                      '/${switch (category) {
                        SearchCategory.album => 'album',
                        SearchCategory.artist => 'artist',
                        SearchCategory.mv => 'mv',
                        _ => 'playlist',
                      }}',
                      extra: item,
                    ),
                  );
                }
                return Obx(
                  () => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        if (!supported)
                          HyperText('此音源不支持${category.title}搜索')
                        else if (controller.loading.value)
                          const HyperText('正在搜索…')
                        else if (controller.error.value.isNotEmpty) ...[
                          HyperText('搜索失败：${controller.error.value}'),
                          HyperButton.text(
                            onPressed: controller.loadMore,
                            label: const HyperText('重试'),
                          ),
                          HyperButton.text(
                            onPressed: () =>
                                showPluginLogs(context, pluginId: selected),
                            label: const HyperText('查看插件日志'),
                          ),
                        ] else if (controller.hasMore.value)
                          HyperButton.text(
                            onPressed: controller.loadMore,
                            label: const HyperText('加载更多'),
                          )
                        else if (count == 0)
                          HyperResult.empty(
                            title: controller.keyword.isEmpty
                                ? '输入关键词开始搜索'
                                : '没有找到${category.title}',
                            showIllustration: false,
                          )
                        else
                          const HyperText('已加载全部结果'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          onSearch: (value) => search(value, selected, category),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              (desktop ? tabHeight : tabHeight * 2 + 8) + 24,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: desktop
                  ? Row(
                      children: [
                        Expanded(child: sites),
                        const SizedBox(width: 24),
                        Expanded(child: categories),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [sites, const SizedBox(height: 8), categories],
                    ),
            ),
          ),
        );
      });
    },
  );
}
