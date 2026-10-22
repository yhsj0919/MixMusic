import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../common/entity/song.dart';
import '../../common/player/player_controller.dart';
import '../../common/plugin/song_matcher.dart';

Future<void> showLyricCandidates(
  BuildContext context,
  PlayerController player,
) async {
  final original = player.song.value;
  if (original == null) return;
  var future = player.plugins.lyricMatcher.candidates(original);
  final selected = await showHyperDialog<Song>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => HyperDialog(
        title: const HyperText('歌词候选'),
        content: SizedBox(
          width: 480,
          height: 360,
          child: FutureBuilder<List<Song>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) return HyperText('搜索失败：${snapshot.error}');
              if (!snapshot.hasData) {
                return const Center(child: HyperText('正在搜索…'));
              }
              final items = snapshot.data!;
              return ListView(
                children: [
                  HyperListTile(
                    title: const HyperText('原歌曲歌词'),
                    subtitle: HyperText(original.title),
                    onTap: () => context.pop(
                      Song.fromJson(original.toJson())..matchedSong = null,
                    ),
                  ),
                  if (items.isEmpty) const HyperText('暂无候选，请先在歌词匹配设置中选择来源'),
                  for (final item in items)
                    HyperListTile(
                      title: HyperText(item.title),
                      subtitle: HyperText(
                        '${SongMatcher.artist(item)} · ${player.plugins.manager.find(item.pluginId)?.record.name ?? item.pluginId} · ${SongMatcher.score(original, item).toStringAsFixed(1)}分',
                      ),
                      trailing:
                          player.lyricSource.value != null &&
                              SongMatcher.sameSong(
                                player.lyricSource.value!,
                                item,
                              )
                          ? const HyperIcon(Icons.check)
                          : null,
                      onTap: () => context.pop(item),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          HyperButton.text(
            label: const HyperText('重新搜索'),
            onPressed: () => setState(() {
              future = player.plugins.lyricMatcher.candidates(
                original,
                refresh: true,
              );
            }),
          ),
          HyperButton.text(
            label: const HyperText('关闭'),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    ),
  );
  if (selected == null) return;
  final changed = await player.switchLyric(original, selected);
  if (!changed &&
      context.mounted &&
      player.song.value != null &&
      SongMatcher.sameSong(player.song.value!, original)) {
    await showHyperDialog<void>(
      context: context,
      builder: (context) => HyperDialog(
        title: const HyperText('未切换歌词'),
        content: const HyperText('所选候选未返回可用歌词，保留当前歌词'),
        actions: [
          HyperButton.text(
            label: const HyperText('关闭'),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
