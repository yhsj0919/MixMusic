import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/player/player_controller.dart';
import '../../common/player/player_format.dart';

Future<void> showSleepTimer(BuildContext context) {
  final player = context.lx.find<PlayerController>();
  final timer = player.sleepTimer;
  return showHyperDialog<void>(
    context: context,
    builder: (context) => HyperDialog(
      title: const HyperText('定时停止播放'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => HyperListTile(
              title: HyperText('选择时间：${timer.minutes.value} 分钟'),
              trailing: HyperSwitch(
                value: timer.active,
                onChanged: (value) =>
                    value ? timer.start(timer.minutes.value) : timer.cancel(),
              ),
            ),
          ),
          Obx(
            () => HyperSlider(
              value: timer.minutes.value / 90,
              onChanged: (value) => timer.minutes.value = (value * 90).round(),
              onChangeEnd: (value) => timer.start((value * 90).round()),
            ),
          ),
          Obx(
            () => HyperText(
              timer.waiting.value
                  ? '等待本曲结束后停止'
                  : timer.active
                  ? '${formatTime(timer.remaining.value)} 后停止播放'
                  : '未开启定时',
            ),
          ),
          Obx(
            () => HyperListTile(
              title: const HyperText('到时播完整首歌再停止'),
              trailing: HyperSwitch(
                value: timer.finishSong.value,
                onChanged: (value) => timer.finishSong.value = value,
              ),
            ),
          ),
          Obx(
            () => HyperButton.tonal(
              onPressed: player.song.value == null
                  ? null
                  : () {
                      timer.afterSong();
                      context.pop();
                    },
              label: const HyperText('本曲结束后停止'),
            ),
          ),
          HyperButton.text(
            onPressed: timer.cancel,
            label: const HyperText('取消定时'),
          ),
        ],
      ),
    ),
  );
}
