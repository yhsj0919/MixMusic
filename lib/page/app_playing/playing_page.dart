import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_lyric/lemon_lyric.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/player/player_controller.dart';
import 'player_page.dart';
import 'source_candidates.dart';
import 'lyric_candidates.dart';

class PlayingPage extends StatelessWidget {
  const PlayingPage({super.key, required this.player});
  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final lyric = player.lyrics;
    final desktop = HyperDeviceDetector.of(context) == HyperDeviceType.desktop;
    final information = Obx(() {
      final song = player.song.value;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: desktop ? 280 : 120,
            height: desktop ? 280 : 120,
            child: song?.cover == null || song!.cover!.isEmpty
                ? const HyperIcon(Icons.music_note_rounded, size: 72)
                : Image.network(
                    song.cover!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) =>
                        const HyperIcon(Icons.music_note_rounded, size: 72),
                  ),
          ),
          const SizedBox(height: 16),
          HyperText(song?.title ?? '尚未播放', variant: HyperTextVariant.bodyLarge),
          if (song?.subtitle != null) HyperText(song!.subtitle!),
          if (player.lyricSource.value != null)
            HyperText(
              '歌词来源：${player.plugins.manager.find(player.lyricSource.value!.pluginId)?.record.name ?? player.lyricSource.value!.pluginId}',
            ),
          if (song?.matchedSong != null)
            HyperText(
              '播放来源：${player.plugins.manager.find(song!.actualSong.pluginId)?.record.name ?? song.actualSong.pluginId} · 音质 ${song.actualSong.playQuality ?? '未知'}',
            ),
          if (song != null)
            HyperBadge(
              label: switch (song.favorited) {
                true => '已收藏',
                false => '未收藏',
                null => '收藏未知',
              },
            ),
        ],
      );
    });
    final lyrics = ValueListenableBuilder(
      valueListenable: lyric.controller.loadStateListenable,
      builder: (context, state, child) =>
          lyric.controller.document.lines.isEmpty
          ? const Center(child: HyperText('暂无歌词'))
          : LyricView(
              controller: lyric.controller,
              style: LyricViewStyle(
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                ),
                activeTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
    );
    return HyperScaffold(
      appBar: HyperAppBar(
        title: const HyperText('正在播放'),
        automaticallyImplyLeading: false,
        actions: [
          HyperIconButton.ghost(
            tooltip: '歌词候选',
            icon: const HyperIcon(Icons.lyrics_outlined),
            onPressed: () => showLyricCandidates(context, player),
          ),
          HyperIconButton.ghost(
            tooltip: '音源候选',
            icon: const HyperIcon(Icons.compare_arrows),
            onPressed: () => showSourceCandidates(context, player),
          ),
        ],
        leading: desktop
            ? null
            : HyperIconButton.ghost(
                icon: const HyperIcon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: desktop
            ? Row(
                children: [
                  Expanded(child: information),
                  Expanded(child: lyrics),
                ],
              )
            : Column(
                children: [
                  information,
                  const SizedBox(height: 16),
                  Expanded(child: lyrics),
                ],
              ),
      ),
      bottomBar: const SafeArea(top: false, child: PlayerPage()),
    );
  }
}
