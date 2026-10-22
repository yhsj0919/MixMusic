import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/player/player_format.dart';
import '../../common/player/player_controller.dart';
import '../setting/extension/plugin_logs.dart';
import 'player_queue.dart';
import 'player_settings.dart';
import 'song_actions.dart';
import '../timer/timer_close_page.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, this.expanded = false});
  final bool expanded;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  double? seekValue;

  @override
  Widget build(BuildContext context) {
    final expanded = widget.expanded;
    final player = context.lx.find<PlayerController>();
    if (!expanded) return _bar(context, player);
    return HyperCard(
      child: Column(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (expanded) const Spacer(),
          Obx(
            () => HyperListTile(
              onTap: () {
                if (GoRouterState.of(context).uri.path != '/playing') {
                  context.push('/playing');
                }
              },
              title: HyperText(player.song.value?.title ?? '尚未播放'),
              subtitle: HyperText(
                player.song.value?.subtitle ??
                    (expanded ? '选择歌曲后显示封面与歌词' : '选择歌曲开始播放'),
              ),
              leading: const HyperIcon(Icons.music_note_rounded),
              trailing: Obx(
                () => HyperButton.tonal(
                  onPressed: player.song.value == null ? null : player.toggle,
                  label: HyperIcon(
                    player.playing.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HyperIconButton.ghost(
                  tooltip: player.mode.value.title,
                  icon: HyperIcon(switch (player.mode.value) {
                    PlayMode.sequence => Icons.arrow_right_alt,
                    PlayMode.loop => Icons.repeat_rounded,
                    PlayMode.single => Icons.repeat_one_rounded,
                    PlayMode.shuffle => Icons.shuffle_rounded,
                  }),
                  onPressed: player.cycleMode,
                ),
                HyperIconButton.ghost(
                  tooltip: '上一首',
                  icon: const HyperIcon(Icons.skip_previous_rounded),
                  onPressed: player.hyperQueue.entries.value.isEmpty
                      ? null
                      : player.previous,
                ),
                HyperIconButton.ghost(
                  tooltip: '下一首',
                  icon: const HyperIcon(Icons.skip_next_rounded),
                  onPressed: player.hyperQueue.entries.value.isEmpty
                      ? null
                      : player.next,
                ),
                HyperIconButton.ghost(
                  tooltip: '播放列表（${player.queue.value.length}）',
                  icon: const HyperIcon(Icons.queue_music_rounded),
                  onPressed: () => showPlayerQueue(context),
                ),
                HyperIconButton.ghost(
                  tooltip: player.sleepTimer.waiting.value
                      ? '本曲结束后停止'
                      : player.sleepTimer.active
                      ? '${formatTime(player.sleepTimer.remaining.value)} 后停止'
                      : '定时停止播放',
                  icon: HyperIcon(
                    player.sleepTimer.active
                        ? Icons.timer
                        : Icons.timer_outlined,
                  ),
                  onPressed: () => showSleepTimer(context),
                ),
                HyperIconButton.ghost(
                  tooltip: '播放设置',
                  icon: const HyperIcon(Icons.tune_rounded),
                  onPressed: () => showPlayerSettings(context),
                ),
              ],
            ),
          ),
          Obx(() {
            final length = player.duration.value.inMilliseconds;
            return HyperSlider(
              value:
                  seekValue ??
                  (length == 0
                      ? 0
                      : (player.position.value.inMilliseconds / length).clamp(
                          0.0,
                          1.0,
                        )),
              onChanged: length == 0
                  ? null
                  : (value) => setState(() => seekValue = value),
              onChangeEnd: length == 0
                  ? null
                  : (value) {
                      player.seek(
                        Duration(milliseconds: (value * length).round()),
                      );
                      setState(() => seekValue = null);
                    },
            );
          }),
          Obx(
            () => HyperText(
              '${formatTime(seekValue == null ? player.position.value : Duration(milliseconds: (seekValue! * player.duration.value.inMilliseconds).round()))} / ${formatTime(player.duration.value)}',
            ),
          ),
          Obx(
            () => player.song.value?.playQuality == null
                ? const SizedBox.shrink()
                : HyperText('当前音质：${player.song.value!.playQuality}'),
          ),
          Obx(
            () => player.status.value.isEmpty
                ? const SizedBox.shrink()
                : HyperListTile(
                    title: HyperText(player.status.value),
                    onTap: () => showPluginLogs(
                      context,
                      pluginId: player.song.value?.pluginId,
                    ),
                  ),
          ),
          if (expanded) ...[
            Obx(
              () =>
                  HyperText(player.lyric.value == null ? '歌词尚未加载' : '歌词已独立加载'),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, PlayerController player) {
    final desktop = HyperDeviceDetector.of(context) == HyperDeviceType.desktop;
    return HyperCard(
      style: HyperCardStyle(padding: const EdgeInsets.symmetric(horizontal: 8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final duration = player.duration.value.inMilliseconds;
            final value =
                seekValue ??
                (duration == 0
                    ? 0.0
                    : (player.position.value.inMilliseconds / duration).clamp(
                        0.0,
                        1.0,
                      ));
            return SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (desktop)
                    HyperText(
                      formatTime(
                        Duration(milliseconds: (value * duration).round()),
                      ),
                      variant: HyperTextVariant.caption,
                    ),
                  Expanded(
                    child: HyperSlider(
                      variant: HyperSliderVariant.thin,
                      value: value,
                      onChanged: duration == 0
                          ? null
                          : (value) => setState(() => seekValue = value),
                      onChangeEnd: duration == 0
                          ? null
                          : (value) {
                              player.seek(
                                Duration(
                                  milliseconds: (value * duration).round(),
                                ),
                              );
                              setState(() => seekValue = null);
                            },
                    ),
                  ),
                  if (desktop)
                    HyperText(
                      formatTime(player.duration.value),
                      variant: HyperTextVariant.caption,
                    ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = desktop && constraints.maxWidth >= 900;
                final info = Obx(() {
                  final song = player.song.value;
                  return HyperListTile(
                    onTap: () {
                      if (GoRouterState.of(context).uri.path != '/playing') {
                        context.push('/playing');
                      }
                    },
                    leading: HyperAvatar(
                      image: song?.cover == null || song!.cover!.isEmpty
                          ? null
                          : NetworkImage(song.cover!),
                      icon: const HyperIcon(Icons.music_note_rounded),
                      shape: HyperAvatarShape.rounded,
                      style: const HyperAvatarStyle(size: 48, radius: 6),
                    ),
                    title: HyperText(
                      song?.title ?? '尚未播放',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: HyperText(
                      song?.subtitle ?? '选择歌曲开始播放',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                });
                final controls = Obx(
                  () => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (desktop)
                        HyperIconButton.ghost(
                          tooltip: player.mode.value.title,
                          icon: HyperIcon(switch (player.mode.value) {
                            PlayMode.sequence => Icons.arrow_right_alt,
                            PlayMode.loop => Icons.repeat_rounded,
                            PlayMode.single => Icons.repeat_one_rounded,
                            PlayMode.shuffle => Icons.shuffle_rounded,
                          }),
                          onPressed: player.cycleMode,
                        ),
                      if (desktop)
                        HyperIconButton.ghost(
                          tooltip: '上一首',
                          icon: const HyperIcon(Icons.skip_previous_rounded),
                          onPressed: player.hyperQueue.entries.value.isEmpty
                              ? null
                              : player.previous,
                        ),
                      HyperIconButton.ghost(
                        tooltip: player.playing.value ? '暂停' : '播放',
                        icon: HyperIcon(
                          player.playing.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: player.song.value == null
                            ? null
                            : player.toggle,
                      ),
                      HyperIconButton.ghost(
                        tooltip: '下一首',
                        icon: const HyperIcon(Icons.skip_next_rounded),
                        onPressed: player.hyperQueue.entries.value.isEmpty
                            ? null
                            : player.next,
                      ),
                      if (wide && player.song.value?.playQuality != null)
                        HyperButton.ghost(
                          label: HyperText('${player.song.value!.playQuality}'),
                          onPressed: () => showPlayerSettings(context),
                        ),
                    ],
                  ),
                );
                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HyperIconButton.ghost(
                      tooltip: '播放列表',
                      icon: const HyperIcon(Icons.queue_music_rounded),
                      onPressed: () => showPlayerQueue(context),
                    ),
                    if (wide) ...[
                      Obx(
                        () => HyperIconButton.ghost(
                          tooltip: '下载',
                          icon: const HyperIcon(Icons.download_rounded),
                          onPressed: player.song.value == null
                              ? null
                              : () => selectAndPlay(
                                  context,
                                  player.song.value!,
                                  action: SongAction.download,
                                ),
                        ),
                      ),
                      Obx(
                        () => HyperIconButton.ghost(
                          tooltip: player.sleepTimer.waiting.value
                              ? '本曲结束后停止'
                              : player.sleepTimer.active
                              ? '${formatTime(player.sleepTimer.remaining.value)} 后停止'
                              : '定时停止播放',
                          icon: HyperIcon(
                            player.sleepTimer.active
                                ? Icons.timer
                                : Icons.timer_outlined,
                          ),
                          onPressed: () => showSleepTimer(context),
                        ),
                      ),
                      HyperIconButton.ghost(
                        tooltip: '音量',
                        icon: const HyperIcon(Icons.volume_up_rounded),
                        onPressed: () => showPlayerSettings(context),
                      ),
                    ],
                    HyperIconButton.ghost(
                      tooltip: '播放设置',
                      icon: const HyperIcon(Icons.tune_rounded),
                      onPressed: () => showPlayerSettings(context),
                    ),
                  ],
                );
                return Row(
                  children: [
                    Expanded(child: info),
                    controls,
                    if (wide)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: actions,
                        ),
                      )
                    else
                      actions,
                  ],
                );
              },
            ),
          ),
          Obx(
            () => player.status.value.isEmpty
                ? const SizedBox.shrink()
                : HyperListTile(
                    title: HyperText(player.status.value),
                    onTap: () => showPluginLogs(
                      context,
                      pluginId: player.song.value?.pluginId,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
