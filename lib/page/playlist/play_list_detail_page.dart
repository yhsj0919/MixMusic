import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/player/player_controller.dart';
import '../../common/plugin/collection_controller.dart';
import '../../common/plugin/plugin_controller.dart';
import '../app_playing/song_actions.dart';
import '../download/download_actions.dart';

class PlayListDetailPage extends StatefulWidget {
  const PlayListDetailPage({
    super.key,
    required this.collection,
    this.embedded = false,
  });
  final CollectionController collection;
  final bool embedded;

  @override
  State<PlayListDetailPage> createState() => _PlayListDetailPageState();
}

class _PlayListDetailPageState extends State<PlayListDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.collection.page == 0) widget.collection.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final player = context.lx.find<PlayerController>();
    final plugins = context.lx.find<PluginController>();
    return HyperScaffold(
      appBar: widget.embedded
          ? null
          : HyperAppBar(
              title: HyperText(collection.resource.title),
              automaticallyImplyLeading: false,
              leading:
                  HyperDeviceDetector.of(context) == HyperDeviceType.desktop
                  ? null
                  : HyperIconButton.ghost(
                      tooltip: '返回',
                      icon: const HyperIcon(Icons.arrow_back_rounded),
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                    ),
            ),
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (event) {
          if (event.depth == 0 &&
              event.metrics.extentAfter < 240 &&
              collection.error.value.isEmpty) {
            collection.loadMore();
          }
          return false;
        },
        child: Obx(() {
          final songs = collection.songs.value;
          final info = collection.info.value;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: songs.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyperText(info.title),
                    if (info.favorited != null)
                      HyperBadge(label: info.favorited! ? '已收藏' : '未收藏'),
                    if (info.subtitle != null) HyperText('${info.subtitle}'),
                    if (info.description != null)
                      HyperText('${info.description}'),
                    Wrap(
                      spacing: 8,
                      children: [
                        HyperButton.filled(
                          onPressed: songs.isEmpty
                              ? null
                              : () => player.addCollection(
                                  collection,
                                  play: true,
                                ),
                          label: const HyperText('播放全部'),
                        ),
                        HyperButton.tonal(
                          onPressed: songs.isEmpty
                              ? null
                              : () => player.addCollection(collection),
                          label: const HyperText('加入播放列表'),
                        ),
                        HyperButton.tonal(
                          onPressed: () =>
                              downloadCollection(context, collection),
                          label: const HyperText('下载全部'),
                        ),
                        if (collection.supportsFavorite)
                          HyperMenuButton(
                            items: [
                              if (info.favorited != true)
                                const HyperMenuItem(
                                  id: 'favorite',
                                  label: '收藏',
                                ),
                              if (info.favorited != false)
                                const HyperMenuItem(
                                  id: 'unfavorite',
                                  label: '取消收藏',
                                ),
                            ],
                            onSelected: (action) => plugins.manage(
                              collection.resource.pluginId,
                              () async {
                                final value = action == 'favorite';
                                await collection.favorite(value);
                                return value ? '已收藏' : '已取消收藏';
                              },
                            ),
                            child: const HyperIcon(Icons.more_horiz),
                          ),
                        if (collection.kind == CollectionKind.artist &&
                            collection.api.supportsArtistAlbums)
                          HyperButton.tonal(
                            onPressed: () => context.push(
                              '/artist/albums',
                              extra: collection.resource,
                            ),
                            label: const HyperText('查看专辑'),
                          ),
                      ],
                    ),
                    HyperText(
                      '已加载 ${songs.length} 首${info.total == null ? '' : ' / ${info.total} 首'}',
                    ),
                    Obx(
                      () => plugins.action.hasError
                          ? HyperText('操作失败：${plugins.action.errorValue}')
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              }
              if (index <= songs.length) {
                final song = songs[index - 1];
                return HyperListTile(
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
                  leading: const HyperIcon(Icons.music_note_rounded),
                  trailing: HyperIconButton.ghost(
                    tooltip: '歌曲操作',
                    icon: const HyperIcon(Icons.more_horiz),
                    onPressed: () async {
                      await showSongActions(
                        context,
                        song,
                        removeFromPlaylist: collection.canRemoveSongs
                            ? () => collection.removeSong(song)
                            : null,
                      );
                      if (mounted) collection.songs.refresh();
                    },
                  ),
                  onTap: () => selectAndPlay(context, song),
                );
              }
              return Obx(
                () => Column(
                  children: [
                    if (collection.loading.value)
                      const HyperText('正在加载…')
                    else if (collection.error.value.isNotEmpty) ...[
                      HyperText('加载失败：${collection.error.value}'),
                      HyperButton.text(
                        onPressed: collection.loadMore,
                        label: const HyperText('重试'),
                      ),
                    ] else if (collection.hasMore.value)
                      HyperButton.text(
                        onPressed: collection.loadMore,
                        label: const HyperText('加载更多'),
                      )
                    else
                      HyperText(songs.isEmpty ? '暂无歌曲' : '已加载全部歌曲'),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
