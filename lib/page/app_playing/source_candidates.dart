import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../common/entity/song.dart';
import '../../common/player/player_controller.dart';
import '../../common/plugin/song_matcher.dart';

Future<void> showSourceCandidates(
  BuildContext context,
  PlayerController player,
) async {
  final original = player.song.value;
  if (original == null) return;
  var future = player.plugins.matcher.candidates(original);
  final selected = await showHyperDialog<Song>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => HyperDialog(
        title: const HyperText('音源候选'),
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
                    title: const HyperText('原音源'),
                    subtitle: HyperText(original.title),
                    onTap: () => context.pop(
                      Song.fromJson(original.toJson())..matchedSong = null,
                    ),
                  ),
                  if (items.isEmpty) const HyperText('暂无候选，请先在音源匹配设置中选择音源'),
                  for (final item in items)
                    HyperListTile(
                      title: HyperText(item.title),
                      subtitle: HyperText(
                        '${SongMatcher.artist(item)} · ${player.plugins.manager.find(item.pluginId)?.record.name ?? item.pluginId} · ${SongMatcher.score(original, item).toStringAsFixed(1)}分',
                      ),
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
              future = player.plugins.matcher.candidates(
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
  if (selected != null) await player.switchSource(original, selected);
}
