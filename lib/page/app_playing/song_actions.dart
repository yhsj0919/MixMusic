import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/song.dart';
import '../../common/download/download_controller.dart';
import '../../common/player/player_controller.dart';
import '../../common/plugin/plugin_controller.dart';
import '../../common/entity/play_list.dart';
import '../../common/plugin/song_matcher.dart';

enum SongAction {
  play,
  append,
  next,
  download,
  favorite,
  unfavorite,
  playlist,
  remove,
  comments,
}

Future<void> showSongActions(
  BuildContext context,
  Song song, {
  Future<void> Function()? removeFromPlaylist,
}) async {
  final plugins = context.lx.find<PluginController>();
  final exports =
      plugins.manager
          .find(song.pluginId)
          ?.installed
          ?.extension
          .service
          ?.publicExports ??
      const <String>[];
  final action = await showHyperDialog<SongAction>(
    context: context,
    builder: (context) => HyperDialog(
      title: HyperText(song.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in SongAction.values)
            if ((item != SongAction.favorite && item != SongAction.unfavorite ||
                    exports.contains('favoriteSong')) &&
                (item != SongAction.favorite || song.favorited != true) &&
                (item != SongAction.unfavorite || song.favorited != false) &&
                (item != SongAction.remove || removeFromPlaylist != null) &&
                (item != SongAction.comments ||
                    exports.contains('songComments')) &&
                (item != SongAction.playlist ||
                    exports.contains('addToPlayList') &&
                        exports.contains('myPlayLists')))
              HyperListTile(
                title: HyperText(switch (item) {
                  SongAction.play => '立即播放',
                  SongAction.append => '加入播放列表',
                  SongAction.next => '下一首播放',
                  SongAction.download => '下载',
                  SongAction.favorite => '添加到喜欢',
                  SongAction.unfavorite => '取消喜欢',
                  SongAction.playlist => '添加到歌单',
                  SongAction.remove => '从歌单移除',
                  SongAction.comments => '评论',
                }),
                onTap: () => context.pop(item),
              ),
        ],
      ),
    ),
  );
  if (action == SongAction.remove && context.mounted) {
    final confirmed = await showHyperDialog<bool>(
      context: context,
      builder: (context) => HyperDialog(
        title: const HyperText('从歌单移除'),
        content: HyperText(song.title),
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
    if (confirmed == true) {
      await plugins.manage(song.pluginId, () async {
        await removeFromPlaylist!();
        return '已从歌单移除';
      });
    }
    return;
  }
  if (action != null && context.mounted) {
    if (action == SongAction.comments) {
      context.push('/comments', extra: song);
      return;
    }
    await selectAndPlay(context, song, action: action);
  }
}

Future<void> selectAndPlay(
  BuildContext context,
  Song song, {
  SongAction action = SongAction.play,
}) async {
  if (action == SongAction.favorite ||
      action == SongAction.unfavorite ||
      action == SongAction.playlist) {
    final plugins = context.lx.find<PluginController>();
    await plugins.manage(song.pluginId, () async {
      final api = plugins.music(song.pluginId);
      if (action == SongAction.playlist) {
        var page = 0;
        var result = await api.myPlayLists(true, page);
        if (!context.mounted) return '已取消';
        final items = [...result.items];
        var loading = false;
        var error = '';
        final playlist = await showHyperDialog<PlayList>(
          context: context,
          builder: (context) => HyperDialog(
            title: const HyperText('选择歌单'),
            content: SizedBox(
              width: 360,
              height: 360,
              child: StatefulBuilder(
                builder: (context, setState) => ListView(
                  children: [
                    for (final item in items)
                      HyperListTile(
                        title: HyperText(item.title),
                        onTap: () => context.pop(item),
                      ),
                    if (items.isEmpty && !result.hasMore)
                      const HyperText('暂无创建的歌单，请先到“我的”创建'),
                    if (error.isNotEmpty) HyperText(error),
                    if (result.hasMore)
                      HyperButton.text(
                        onPressed: loading
                            ? null
                            : () async {
                                setState(() {
                                  loading = true;
                                  error = '';
                                });
                                try {
                                  final next = await api.myPlayLists(
                                    true,
                                    page + 1,
                                  );
                                  if (!context.mounted) return;
                                  setState(() {
                                    result = next;
                                    items.addAll(next.items);
                                    page++;
                                  });
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() => error = '$e');
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => loading = false);
                                  }
                                }
                              },
                        label: HyperText(loading ? '正在加载…' : '加载更多'),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              HyperButton.text(
                onPressed: () => context.pop(),
                label: const HyperText('取消'),
              ),
            ],
          ),
        );
        if (playlist == null) return '已取消';
        await api.addToPlayList(playlist, [song]);
        return '已添加到歌单';
      }
      await api.favoriteSong(song, action == SongAction.favorite);
      return action == SongAction.favorite ? '已添加到喜欢' : '已取消喜欢';
    });
    return;
  }
  final player = context.lx.find<PlayerController>();
  if (!context.mounted) return;
  if (action == SongAction.download) {
    final current = player.song.value;
    final selected =
        current != null &&
            current.pluginId == song.pluginId &&
            SongMatcher.sameSong(current, song) &&
            current.matchedSong != null
        ? current
        : song;
    context.lx.find<DownloadController>().add(selected);
    context.go('/settings/downloads');
  } else if (action == SongAction.play) {
    await player.playSong(song);
  } else {
    player.addSong(song, next: action == SongAction.next);
  }
}
