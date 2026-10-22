import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../common/player/music_cache.dart';
import '../extension/plugin_logs.dart';

class CacheSettingPage extends StatelessWidget {
  const CacheSettingPage({super.key, required this.cache});
  final MusicCache cache;

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: const HyperText('存储与缓存'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/settings'),
            ),
    ),
    body: FutureBuilder<void>(
      future: cache.restored,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return HyperResult.empty(
            title: '缓存配置读取失败',
            description: '${snapshot.error}',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: HyperText('正在读取…'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Obx(
              () => HyperListTile(
                title: const HyperText('音乐缓存'),
                subtitle: const HyperText('同音质优先使用完整缓存，不重复请求音频'),
                trailing: HyperSwitch(
                  value: cache.enabled.value,
                  onChanged: cache.setEnabled,
                ),
              ),
            ),
            Obx(
              () => HyperText(
                '已用 ${(cache.usedBytes.value / 1024 / 1024).toStringAsFixed(1)} MB / 上限 ${cache.limitBytes.value ~/ 1024 ~/ 1024} MB',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mb in [64, 128, 256, 512, 1024])
                  HyperButton.tonal(
                    onPressed: () => cache.setLimit(mb * 1024 * 1024),
                    label: HyperText('$mb MB'),
                  ),
              ],
            ),
            HyperButton.tonal(
              onPressed: cache.clear,
              label: const HyperText('清理音乐缓存'),
            ),
            const HyperText('正在使用的文件暂不清理；不影响正式下载和本地音乐。分段资源、未知长度和不完整内容暂不缓存。'),
            HyperButton.text(
              onPressed: () => showPluginLogs(context, pluginId: 'cache'),
              label: const HyperText('查看缓存日志'),
            ),
          ],
        );
      },
    ),
  );
}
