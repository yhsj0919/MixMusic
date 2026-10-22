import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import 'setting_controller.dart';
import 'extension/plugin_logs.dart';
import '../../common/player/player_controller.dart';
import '../../common/plugin/plugin_controller.dart';
import '../../common/download/download_controller.dart';
import '../../common/entity/quality.dart';
import '../app_playing/quality_dialog.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key, required this.controller});
  final SettingController controller;

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar.large(
      title: const Text('设置'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              key: const ValueKey('page-back'),
              tooltip: '返回',
              onPressed: () => context.go('/'),
              icon: const HyperIcon(Icons.arrow_back_rounded),
            ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('外观', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        HyperCard(
          child: Obx(
            () => HyperListTile(
              title: const Text('深色模式'),
              subtitle: const Text('切换应用整体主题'),
              leading: const Icon(Icons.dark_mode_outlined),
              trailing: HyperSwitch(
                value: controller.darkMode.value,
                onChanged: controller.setDarkMode,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('音乐与插件', style: Theme.of(context).textTheme.titleLarge),
        HyperListTile(
          title: const HyperText('插件日志'),
          leading: const HyperIcon(Icons.bug_report_outlined),
          onTap: () => showPluginLogs(context),
        ),
        const SizedBox(height: 12),
        HyperCard(
          child: Column(
            children: [
              Obx(() {
                final plugins = context.lx.find<PluginController>();
                final names = {
                  for (final entry in plugins.homeSources)
                    entry.id: entry.record.name,
                };
                return HyperListTile(
                  title: const HyperText('默认首页音源'),
                  subtitle: HyperText(
                    names[plugins.selectedId.value] ?? '尚未选择',
                  ),
                  leading: const HyperIcon(Icons.home_outlined),
                  onTap: () async {
                    await plugins.restored;
                    if (!context.mounted) return;
                    final sources = plugins.homeSources;
                    final id = await showHyperDialog<String>(
                      context: context,
                      builder: (context) => HyperDialog(
                        title: const HyperText('默认首页音源'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sources.isEmpty) const HyperText('请先安装并启用音源插件'),
                            for (final entry in sources)
                              HyperListTile(
                                title: HyperText(entry.record.name),
                                onTap: () => context.pop(entry.id),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (id != null) await plugins.selectSource(id);
                  },
                );
              }),
              HyperListTile(
                title: const HyperText('音乐目录'),
                subtitle: const HyperText('管理本地音乐文件夹'),
                leading: const HyperIcon(Icons.folder_outlined),
                onTap: () => context.go('/settings/local'),
              ),
              HyperListTile(
                title: const HyperText('存储与缓存'),
                subtitle: const HyperText('音乐缓存开关、容量与清理'),
                leading: const HyperIcon(Icons.storage_outlined),
                onTap: () => context.go('/settings/cache'),
              ),
              HyperListTile(
                title: const HyperText('下载'),
                subtitle: const HyperText('下载任务、进度与重试'),
                leading: const HyperIcon(Icons.download_outlined),
                onTap: () => context.go('/settings/downloads'),
              ),
              HyperListTile(
                title: const HyperText('插件管理'),
                subtitle: const HyperText('安装、更新、启停与卸载'),
                leading: const HyperIcon(Icons.extension_outlined),
                onTap: () => context.go('/settings/extensions'),
              ),
              Obx(() {
                final player = context.lx.find<PlayerController>();
                return HyperListTile(
                  title: const HyperText('默认播放音质'),
                  subtitle: HyperText(
                    Quality.levels[player.defaultQuality.value] ??
                        '${player.defaultQuality.value}',
                  ),
                  leading: const HyperIcon(Icons.tune_rounded),
                  onTap: () async {
                    final value = await selectQuality(
                      context,
                      _qualities,
                      showSize: false,
                    );
                    if (value != null) await player.setDefaultQuality(value);
                  },
                );
              }),
              Obx(() {
                final downloads = context.lx.find<DownloadController>();
                return HyperListTile(
                  title: const HyperText('默认下载音质'),
                  subtitle: HyperText(
                    Quality.levels[downloads.defaultQuality.value] ??
                        '${downloads.defaultQuality.value}',
                  ),
                  leading: const HyperIcon(Icons.audio_file_outlined),
                  onTap: () async {
                    final value = await selectQuality(
                      context,
                      _qualities,
                      showSize: false,
                    );
                    if (value != null) await downloads.setDefaultQuality(value);
                  },
                );
              }),
              const HyperListTile(
                title: HyperText('音质策略'),
                subtitle: HyperText('音质不可用时选择不高于预设的可用音质；播放页切换只对当前歌曲临时生效。'),
              ),
              HyperListTile(
                title: const HyperText('音源匹配'),
                subtitle: const HyperText('自动匹配、参与音源与优先级'),
                leading: const HyperIcon(Icons.compare_arrows),
                onTap: () => context.go('/settings/matching'),
              ),
              HyperListTile(
                title: const HyperText('歌词匹配'),
                subtitle: const HyperText('独立歌词来源、自动匹配与优先级'),
                leading: const HyperIcon(Icons.lyrics_outlined),
                onTap: () => context.go('/settings/lyric-matching'),
              ),
              Obx(() {
                final player = context.lx.find<PlayerController>();
                return HyperListTile(
                  title: const HyperText('与其他应用同时播放'),
                  subtitle: const HyperText('允许音频共存，实际行为取决于系统和其他应用'),
                  trailing: HyperSwitch(
                    value: player.allowConcurrentPlayback.value,
                    onChanged: player.setAllowConcurrentPlayback,
                  ),
                );
              }),
              Obx(() {
                final player = context.lx.find<PlayerController>();
                return HyperListTile(
                  title: const HyperText('标题歌词（蓝牙歌词）'),
                  subtitle: const HyperText('将当前歌词同步为系统媒体标题；需要设备支持，也会影响媒体通知标题'),
                  trailing: HyperSwitch(
                    value: player.titleLyrics.value,
                    onChanged: player.setTitleLyrics,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const HyperCard(
          child: HyperListTile(
            title: Text('关于 MixMusic'),
            subtitle: Text('v2 · 基础验证阶段'),
            leading: Icon(Icons.info_outline_rounded),
          ),
        ),
      ],
    ),
  );

  List<Quality> get _qualities => [
    for (final entry in Quality.levels.entries)
      Quality(
        pluginId: '',
        id: entry.key,
        title: entry.value,
        value: entry.key,
      ),
  ];
}
