import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/player/player_controller.dart';
import '../timer/timer_close_page.dart';

Future<void> showPlayerSettings(BuildContext context) {
  final player = context.lx.find<PlayerController>();
  return showHyperDialog<void>(
    context: context,
    builder: (dialogContext) => HyperDialog(
      title: const HyperText('播放设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => HyperListTile(
              title: HyperText('播放模式：${player.mode.value.title}'),
              onTap: player.cycleMode,
            ),
          ),
          HyperListTile(title: const HyperText('上一首'), onTap: player.previous),
          HyperListTile(
            title: const HyperText('定时停止播放'),
            onTap: () {
              dialogContext.pop();
              showSleepTimer(context);
            },
          ),
          Obx(
            () => HyperListTile(
              title: HyperText('音量 ${(player.volume.value * 100).round()}%'),
              trailing: HyperSwitch(
                value: player.muted.value,
                onChanged: player.setMuted,
              ),
              subtitle: const HyperText('静音'),
            ),
          ),
          Obx(
            () => HyperSlider(
              value: player.volume.value,
              onChanged: player.setVolume,
            ),
          ),
          Obx(() => HyperText('播放速度 ${player.speed.value}×')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                HyperButton.tonal(
                  onPressed: () => player.setSpeed(value),
                  label: HyperText('$value×'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final song = player.song.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HyperText('音质'),
                if (song == null || song.actualSong.qualities.isEmpty)
                  const HyperText('暂无可选音质')
                else
                  for (final quality in song.actualSong.qualities)
                    HyperListTile(
                      title: HyperText(quality.title),
                      trailing: song.actualSong.playQuality == quality.value
                          ? const HyperIcon(Icons.check_rounded)
                          : null,
                      onTap: () => player.changeQuality(quality.value),
                    ),
              ],
            );
          }),
          HyperButton.tonal(
            onPressed: () {
              dialogContext.pop();
              context.push('/equalizer');
            },
            label: const HyperText('均衡器'),
          ),
          Obx(
            () => player.controlError.value.isEmpty
                ? const SizedBox.shrink()
                : HyperText(player.controlError.value),
          ),
        ],
      ),
    ),
  );
}
