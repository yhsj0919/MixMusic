import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/local/local_files.dart';
import '../../common/local/local_music_controller.dart';
import '../../common/player/player_controller.dart';
import '../app_playing/song_actions.dart';

class LocalMusicPage extends StatefulWidget {
  const LocalMusicPage({super.key, required this.controller});
  final LocalMusicController controller;
  @override
  State<LocalMusicPage> createState() => _LocalMusicPageState();
}

class _LocalMusicPageState extends State<LocalMusicPage> {
  final trail = <LocalEntry>[];
  void open(LocalEntry directory, {bool root = false}) {
    setState(() {
      if (root) trail.clear();
      trail.add(directory);
    });
    widget.controller.openDirectory(directory.uri);
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.controller;
    return HyperScaffold(
      appBar: HyperAppBar(
        title: const HyperText('本地音乐'),
        automaticallyImplyLeading: false,
        leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
            ? null
            : HyperIconButton.ghost(
                icon: const HyperIcon(Icons.arrow_back_rounded),
                tooltip: '返回',
                onPressed: () => context.go('/'),
              ),
        actions: [
          HyperButton.text(
            onPressed: () => context.go('/settings/local'),
            label: const HyperText('目录设置'),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: local.restored,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return HyperResult.empty(
              title: '目录配置读取失败',
              description: '${snapshot.error}',
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: HyperText('正在读取目录…'));
          }
          return Column(
            children: [
              Obx(
                () => Wrap(
                  spacing: 8,
                  children: [
                    for (final uri in local.directories.value)
                      HyperButton.tonal(
                        onPressed: () => open(
                          LocalEntry(uri, LocalFiles.name(uri), true),
                          root: true,
                        ),
                        label: HyperText(LocalFiles.name(uri)),
                      ),
                  ],
                ),
              ),
              Wrap(
                children: [
                  for (final (index, entry) in trail.indexed)
                    HyperButton.text(
                      onPressed: () {
                        setState(
                          () => trail.removeRange(index + 1, trail.length),
                        );
                        local.openDirectory(entry.uri);
                      },
                      label: HyperText(entry.name),
                    ),
                ],
              ),
              Expanded(
                child: Obx(() {
                  if (local.selected.value.isEmpty) {
                    return const HyperResult.empty(
                      title: '选择音乐目录',
                      description: '在设置中添加文件夹后，选择目录查看音频文件',
                    );
                  }
                  return local.entries.when(
                    loading: () => const Center(child: HyperText('正在读取文件…')),
                    error: (error, stack) => HyperResult.empty(
                      title: '目录读取失败',
                      description: '$error',
                      actions: [
                        HyperButton.tonal(
                          onPressed: () =>
                              local.openDirectory(local.selected.value),
                          label: const HyperText('重试'),
                        ),
                      ],
                    ),
                    data: (entries) => ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return HyperListTile(
                          title: HyperText(entry.name),
                          leading: HyperIcon(
                            entry.directory
                                ? Icons.folder_outlined
                                : Icons.music_note_rounded,
                          ),
                          onTap: () => entry.directory
                              ? open(entry)
                              : selectAndPlay(context, local.song(entry)),
                          trailing: entry.directory
                              ? null
                              : HyperIconButton.ghost(
                                  tooltip: '歌曲操作',
                                  icon: const HyperIcon(Icons.more_horiz),
                                  onPressed: () => showSongActions(
                                    context,
                                    local.song(entry),
                                  ),
                                ),
                        );
                      },
                    ),
                  );
                }),
              ),
              HyperButton.text(
                onPressed: () {
                  final player = context.lx.find<PlayerController>();
                  for (final entry in local.entries.value ?? <LocalEntry>[]) {
                    if (!entry.directory) player.addSong(local.song(entry));
                  }
                },
                label: const HyperText('本目录歌曲加入播放列表'),
              ),
            ],
          );
        },
      ),
    );
  }
}
