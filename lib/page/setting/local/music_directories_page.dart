import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../common/local/local_files.dart';
import '../../../common/local/local_music_controller.dart';

class MusicDirectoriesPage extends StatefulWidget {
  const MusicDirectoriesPage({super.key, required this.controller});
  final LocalMusicController controller;
  @override
  State<MusicDirectoriesPage> createState() => _MusicDirectoriesPageState();
}

class _MusicDirectoriesPageState extends State<MusicDirectoriesPage> {
  String? error;
  @override
  Widget build(BuildContext context) {
    final local = widget.controller;
    return HyperScaffold(
      appBar: HyperAppBar(
        title: const HyperText('音乐目录'),
        automaticallyImplyLeading: false,
        leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
            ? null
            : HyperIconButton.ghost(
                icon: const HyperIcon(Icons.arrow_back_rounded),
                tooltip: '返回',
                onPressed: () => context.go('/settings'),
              ),
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
          return Obx(
            () => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                HyperButton.filled(
                  onPressed: () async {
                    final directory = await local.files.pickDirectory();
                    if (directory != null) await local.addDirectory(directory);
                  },
                  onError: (value, stack) => setState(() => error = '$value'),
                  label: const HyperText('添加文件夹'),
                ),
                const HyperText('支持添加多个音乐目录。移除只取消关联，不删除文件。'),
                if (error != null) HyperText('操作失败：$error'),
                for (final uri in local.directories.value)
                  HyperListTile(
                    title: HyperText(LocalFiles.name(uri)),
                    subtitle: HyperText(uri),
                    leading: const HyperIcon(Icons.folder_outlined),
                    trailing: HyperIconButton.ghost(
                      tooltip: '移除目录',
                      icon: const HyperIcon(Icons.close_rounded),
                      onPressed: () => local.removeDirectory(uri),
                      onError: (value, stack) =>
                          setState(() => error = '$value'),
                    ),
                  ),
                if (local.directories.value.isEmpty)
                  const HyperResult.empty(title: '尚未设置音乐目录'),
              ],
            ),
          );
        },
      ),
    );
  }
}
