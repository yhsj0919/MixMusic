import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/player/player_controller.dart';

Future<void> showPlayerQueue(BuildContext context) {
  final player = context.lx.find<PlayerController>();
  return showHyperDialog<void>(
    context: context,
    builder: (context) => HyperDialog(
      title: Obx(() => HyperText('播放列表（${player.queue.value.length}）')),
      scrollable: false,
      content: SizedBox(
        width: double.maxFinite,
        height: min(480, MediaQuery.sizeOf(context).height * .6),
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (event) {
            if (event.depth == 0 && event.metrics.extentAfter < 240) {
              player.loadMoreQueue(viewing: true);
            }
            return false;
          },
          child: Obx(() {
            final queue = player.queue.value;
            final entries = player.hyperQueue.entries.value;
            final current = player.currentIndex.value;
            if (entries.isEmpty) return const HyperResult.empty(title: '播放列表为空');
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, row) {
                final entry = entries[row];
                final source = entry.source;
                if (source != null) {
                  return HyperListTile(
                    leading: const HyperIcon(Icons.queue_music_rounded),
                    title: HyperText(source.title),
                    subtitle: HyperText(
                      source.error.value.isEmpty
                          ? '按需加载后续歌曲'
                          : source.error.value,
                    ),
                    trailing: HyperIconButton.ghost(
                      tooltip: '移除歌单',
                      icon: const HyperIcon(Icons.close_rounded),
                      onPressed: () => player.removeCollection(source.key),
                    ),
                  );
                }
                final index = queue.indexOf(entry.item!);
                return HyperListTile(
                  leading: HyperIcon(
                    index == current
                        ? Icons.play_arrow_rounded
                        : Icons.music_note_rounded,
                  ),
                  title: Row(
                    children: [
                      Flexible(child: HyperText(queue[index].title)),
                      const SizedBox(width: 8),
                      HyperBadge(
                        label: switch (queue[index].favorited) {
                          true => '已收藏',
                          false => '未收藏',
                          null => '收藏未知',
                        },
                      ),
                    ],
                  ),
                  subtitle: HyperText(
                    queue[index].subtitle ?? queue[index].pluginId,
                  ),
                  onTap: () => player.playAt(index),
                  trailing: HyperIconButton.ghost(
                    tooltip: '移除',
                    icon: const HyperIcon(Icons.close_rounded),
                    onPressed: () => player.removeSong(index),
                  ),
                );
              },
            );
          }),
        ),
      ),
      actions: [
        HyperButton.text(
          onPressed: () => player.loadMoreQueue(viewing: true, retry: true),
          label: const HyperText('加载更多'),
        ),
        HyperButton.text(
          onPressed: player.clearQueue,
          label: const HyperText('清空列表'),
        ),
        HyperButton.text(
          onPressed: () => context.pop(),
          label: const HyperText('关闭'),
        ),
      ],
    ),
  );
}
