import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../common/entity/song.dart';
import '../../common/history/playback_history_store.dart';
import '../app_playing/song_actions.dart';

class AppHistoryMusicList extends StatefulWidget {
  const AppHistoryMusicList({super.key, required this.store});
  final PlaybackHistoryStore store;

  @override
  State<AppHistoryMusicList> createState() => _AppHistoryMusicListState();
}

class _AppHistoryMusicListState extends State<AppHistoryMusicList> {
  final songs = <Song>[];
  late Future<void> loading = load();
  bool hasMore = true;

  Future<void> load({bool reset = false}) async {
    final page = await widget.store.list(offset: reset ? 0 : songs.length);
    if (!mounted) return;
    setState(() {
      if (reset) songs.clear();
      songs.addAll(page);
      hasMore = page.length == 50;
    });
  }

  void refresh() => setState(() => loading = load(reset: true));

  @override
  void initState() {
    super.initState();
    loading;
  }

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: const HyperText('播放历史'),
      leading: HyperIconButton.ghost(
        icon: const HyperIcon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        HyperButton.text(onPressed: refresh, label: const HyperText('刷新')),
        HyperButton.text(
          onPressed: () async {
            final confirmed = await showHyperDialog<bool>(
              context: context,
              builder: (context) => HyperDialog(
                title: const HyperText('清空播放历史？'),
                content: const HyperText('仅删除历史记录，不删除音乐文件。'),
                actions: [
                  HyperButton.text(
                    onPressed: () => context.pop(false),
                    label: const HyperText('取消'),
                  ),
                  HyperButton.text(
                    onPressed: () => context.pop(true),
                    label: const HyperText('清空'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await widget.store.clear();
            if (mounted) refresh();
          },
          label: const HyperText('清空'),
        ),
      ],
    ),
    body: FutureBuilder<void>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return HyperResult.empty(
            title: '读取历史失败',
            description: '${snapshot.error}',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: HyperText('正在加载…'));
        }
        if (songs.isEmpty) return const HyperResult.empty(title: '暂无播放历史');
        return ListView(
          children: [
            for (final song in songs)
              HyperListTile(
                title: HyperText(song.title),
                subtitle: HyperText(song.subtitle ?? song.pluginId),
                onTap: () => selectAndPlay(context, song),
                trailing: HyperIconButton.ghost(
                  icon: const HyperIcon(Icons.close),
                  tooltip: '移除记录',
                  onPressed: () async {
                    await widget.store.remove(song);
                    if (mounted) refresh();
                  },
                ),
              ),
            if (hasMore)
              HyperButton.text(
                onPressed: () => setState(() => loading = load()),
                label: const HyperText('加载更多'),
              ),
          ],
        );
      },
    ),
  );
}
