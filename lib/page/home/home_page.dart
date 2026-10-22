import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/rank.dart';
import '../../common/plugin/plugin_controller.dart';
import '../app_playing/song_actions.dart';
import '../setting/extension/plugin_logs.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final plugins = context.lx.find<PluginController>();
    final desktop = HyperDeviceDetector.of(context) == HyperDeviceType.desktop;
    return HyperScaffold(
      appBar: HyperAppBar.large(
        title: HyperText(desktop ? '推荐' : 'MixMusic'),
        actions: [
          if (!desktop)
            HyperIconButton.ghost(
              tooltip: '我的',
              icon: const HyperIcon(Icons.library_music_outlined),
              onPressed: () => context.push('/library'),
            ),
          if (!desktop)
            HyperIconButton.ghost(
              tooltip: '搜索',
              icon: const HyperIcon(Icons.search),
              onPressed: () => context.go('/search'),
            ),
          if (!desktop)
            HyperIconButton.ghost(
              tooltip: '每日推荐',
              icon: const HyperIcon(Icons.today_outlined),
              onPressed: () => context.push('/recommend'),
            ),
          if (!desktop)
            HyperIconButton.ghost(
              tooltip: '排行榜',
              icon: const HyperIcon(Icons.leaderboard_outlined),
              onPressed: () => context.push('/ranks'),
            ),
          if (!desktop)
            HyperIconButton.ghost(
              tooltip: '下载',
              icon: const HyperIcon(Icons.download_outlined),
              onPressed: () => context.go('/settings/downloads'),
            ),
          Obx(
            () => HyperIconButton.ghost(
              tooltip: '刷新首页',
              icon: const HyperIcon(Icons.refresh),
              onPressed:
                  plugins.selectedId.value.isEmpty || plugins.home.isLoading
                  ? null
                  : () => plugins.selectSource(plugins.selectedId.value),
            ),
          ),
          if (desktop)
            Obx(
              () => HyperSelect<String>(
                value: plugins.selectedId.value.isEmpty
                    ? null
                    : plugins.selectedId.value,
                placeholder: '首页音源',
                options: [
                  for (final entry in plugins.homeSources)
                    HyperSelectOption(
                      value: entry.id,
                      label: entry.record.name,
                    ),
                ],
                onChanged: (id) {
                  if (id != null && id != plugins.selectedId.value) {
                    plugins.selectSource(id);
                  }
                },
              ),
            ),
          if (!desktop)
            HyperIconButton.ghost(
              tooltip: '设置',
              icon: const HyperIcon(Icons.settings_outlined),
              onPressed: () => context.go('/settings'),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: plugins.homeReady,
        builder: (context, snapshot) => Obx(() {
          if (snapshot.hasError) {
            return HyperResult.empty(
              title: '插件恢复失败',
              description: '${snapshot.error}',
            );
          }
          if (plugins.home.isLoading ||
              (snapshot.connectionState != ConnectionState.done &&
                  plugins.selectedId.value.isEmpty)) {
            return const Center(child: HyperText('正在加载…'));
          }
          if (plugins.home.hasError) {
            return HyperResult.empty(
              title: '首页加载失败',
              description: '${plugins.home.errorValue}',
              actions: [
                HyperButton.text(
                  onPressed: () => showPluginLogs(context),
                  label: const HyperText('查看插件日志'),
                ),
              ],
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              desktop ? 24 : 12,
              8,
              desktop ? 24 : 12,
              32,
            ),
            children: [
              if (!desktop)
                Wrap(
                  spacing: 8,
                  children: [
                    HyperButton.text(
                      onPressed: () => context.push('/artists'),
                      label: const HyperText('全部歌手'),
                    ),
                    HyperButton.text(
                      onPressed: () => context.push('/parse'),
                      label: const HyperText('导入歌单'),
                    ),
                  ],
                ),
              if (const String.fromEnvironment('EXTENSION_MANIFEST').isNotEmpty)
                HyperButton.text(
                  onPressed: () => plugins.loadExternal(
                    const String.fromEnvironment('EXTENSION_MANIFEST'),
                  ),
                  label: const HyperText('加载外部验证插件'),
                ),
              if (plugins.selectedId.value.isEmpty)
                HyperResult.empty(
                  title: '选择首页音源',
                  description: '在设置中安装插件并选择默认首页音源',
                  actions: [
                    HyperButton.tonal(
                      onPressed: () => context.go('/settings'),
                      label: const HyperText('前往设置'),
                    ),
                  ],
                ),
              for (final (key, title, route) in [
                ('playlists', '歌单', '/playlist'),
                ('albums', '专辑', '/album'),
                ('mvs', 'MV', '/mv'),
              ])
                if (plugins.availableSections.contains(key))
                  _section(context, plugins, desktop, key, title, route),
              if (plugins.availableSections.contains('songs'))
                _songs(context, plugins, desktop),
            ],
          );
        }),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    PluginController plugins,
    bool desktop,
    String key,
    String title,
    String route,
  ) {
    final items = plugins.sections.value[key];
    final loading = plugins.sectionLoading.value.contains(key);
    final error = plugins.sectionErrors.value[key];
    final width = desktop
        ? (key == 'mvs' ? 270.0 : 160.0)
        : (key == 'mvs' ? 178.0 : 100.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: HyperText(title, variant: HyperTextVariant.sectionTitle),
              ),
              if (key == 'playlists' || key == 'albums' || key == 'mvs')
                HyperButton.text(
                  onPressed: () => context.push('/$key'),
                  label: const HyperText('查看'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (loading) const HyperText('正在加载…'),
          if (error != null)
            HyperButton.text(
              onPressed: () => plugins.loadSection(key),
              label: const HyperText('重试'),
            ),
          if (error != null)
            HyperText(
              '加载失败：$error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (items != null && items.isEmpty) const HyperText('暂无内容'),
          if (items != null && items.isNotEmpty)
            SizedBox(
              height: desktop
                  ? 200
                  : key == 'mvs'
                  ? 100
                  : 140,
              child: _horizontal(context, items.length, desktop ? 4 : 12, (
                context,
                index,
              ) {
                final item = items[index];
                if (!desktop && key == 'mvs') {
                  return HyperCard(
                    width: 178,
                    style: _cardStyle(false),
                    onTap: () => context.push(route, extra: item),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _cover(item.cover, 12),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          left: 8,
                          child: HyperCard(
                            style: HyperCardStyle(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: HyperText(
                              item.title,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return HyperCard(
                  width: width,
                  style: _cardStyle(desktop),
                  onTap: () => context.push(
                    item is Rank && item.isGroup ? '/ranks' : route,
                    extra: item,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: _cover(item.cover, desktop ? 6 : 12),
                        ),
                      ),
                      SizedBox(
                        height: key == 'playlists' ? 42 : 22,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: HyperText(
                            item.title,
                            maxLines: key == 'playlists' ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: desktop ? 14 : 12,
                              fontWeight: key == 'playlists'
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (key != 'playlists')
                        SizedBox(
                          height: 20,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: HyperText(
                              item.subtitle ?? '',
                              variant: HyperTextVariant.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _songs(BuildContext context, PluginController plugins, bool desktop) {
    final songs = plugins.home.value ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HyperText('新歌', variant: HyperTextVariant.sectionTitle),
          const SizedBox(height: 4),
          if (plugins.sectionLoading.value.contains('songs'))
            const HyperText('正在加载…'),
          if (plugins.sectionErrors.value['songs'] != null)
            HyperButton.text(
              onPressed: () => plugins.loadSection('songs'),
              label: const HyperText('加载失败，重试'),
            ),
          if (desktop && songs.isNotEmpty)
            SizedBox(
              height: 204,
              child: _horizontal(context, songs.length, 4, (context, index) {
                final song = songs[index];
                return HyperCard(
                  width: 160,
                  style: _cardStyle(true),
                  onTap: () => selectAndPlay(context, song),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: _cover(song.cover, 160),
                        ),
                      ),
                      SizedBox(
                        height: 22,
                        child: Row(
                          children: [
                            Expanded(
                              child: HyperText(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            HyperIconButton.ghost(
                              tooltip: '歌曲操作',
                              icon: const HyperIcon(Icons.more_horiz),
                              onPressed: () => showSongActions(context, song),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 22,
                        child: HyperText(
                          song.subtitle ?? '',
                          variant: HyperTextVariant.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            )
          else
            for (final song in songs)
              HyperListTile(
                leading: HyperAvatar(
                  shape: HyperAvatarShape.rounded,
                  image: song.cover == null || song.cover!.isEmpty
                      ? null
                      : NetworkImage(song.cover!),
                  icon: const HyperIcon(Icons.music_note_rounded),
                ),
                title: HyperText(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: HyperText(
                  song.subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => selectAndPlay(context, song),
                trailing: HyperIconButton.ghost(
                  tooltip: '歌曲操作',
                  icon: const HyperIcon(Icons.more_horiz),
                  onPressed: () => showSongActions(context, song),
                ),
              ),
        ],
      ),
    );
  }

  HyperCardStyle _cardStyle(bool desktop) => HyperCardStyle(
    background: const HyperFill.none(),
    border: Border.all(color: Colors.transparent),
    boxShadow: const [],
    borderRadius: BorderRadius.circular(8),
    padding: EdgeInsets.all(desktop ? 4 : 0),
    margin: EdgeInsets.zero,
  );

  Widget _cover(String? url, double radius) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: url == null || url.isEmpty
        ? const Center(child: HyperIcon(Icons.music_note_rounded))
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) =>
                const Center(child: HyperIcon(Icons.music_note_rounded)),
          ),
  );

  Widget _horizontal(
    BuildContext context,
    int count,
    double spacing,
    IndexedWidgetBuilder builder,
  ) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      },
    ),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: count,
      itemBuilder: builder,
      separatorBuilder: (_, index) => SizedBox(width: spacing),
    ),
  );
}
