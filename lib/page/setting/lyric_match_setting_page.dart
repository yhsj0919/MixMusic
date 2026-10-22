import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';

class LyricMatchSettingPage extends StatelessWidget {
  const LyricMatchSettingPage({super.key, required this.plugins});
  final PluginController plugins;

  @override
  Widget build(BuildContext context) {
    final matcher = plugins.lyricMatcher;
    return HyperScaffold(
      appBar: HyperAppBar(
        title: const HyperText('歌词匹配'),
        automaticallyImplyLeading: false,
        leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
            ? null
            : HyperIconButton.ghost(
                icon: const HyperIcon(Icons.arrow_back),
                onPressed: () => context.go('/settings'),
              ),
      ),
      body: Obx(() {
        final ids = matcher.sources.value;
        final entries =
            plugins.extensions.value
                .where((entry) => matcher.available(entry.id))
                .toList()
              ..sort((a, b) {
                final x = ids.indexOf(a.id), y = ids.indexOf(b.id);
                return (x < 0 ? ids.length : x).compareTo(
                  y < 0 ? ids.length : y,
                );
              });
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            HyperListTile(
              title: const HyperText('歌词为空时自动匹配'),
              subtitle: const HyperText('与音频来源独立，原歌词为空或失败时搜索其他来源；适用于本地音乐'),
              trailing: HyperSwitch(
                value: matcher.enabled.value,
                onChanged: matcher.setEnabled,
              ),
            ),
            const HyperText('选择歌词来源，用箭头调整顺序。只搜索和获取歌词，不解析播放地址。'),
            for (final entry in entries)
              HyperListTile(
                title: HyperText(entry.record.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ids.contains(entry.id)) ...[
                      HyperIconButton.ghost(
                        icon: const HyperIcon(Icons.arrow_upward),
                        tooltip: '提高优先级',
                        onPressed: ids.indexOf(entry.id) == 0
                            ? null
                            : () {
                                final next = [...ids];
                                final index = next.indexOf(entry.id);
                                next.removeAt(index);
                                next.insert(index - 1, entry.id);
                                matcher.setSources(next);
                              },
                      ),
                      HyperIconButton.ghost(
                        icon: const HyperIcon(Icons.arrow_downward),
                        tooltip: '降低优先级',
                        onPressed: ids.indexOf(entry.id) == ids.length - 1
                            ? null
                            : () {
                                final next = [...ids];
                                final index = next.indexOf(entry.id);
                                next.removeAt(index);
                                next.insert(index + 1, entry.id);
                                matcher.setSources(next);
                              },
                      ),
                    ],
                    HyperSwitch(
                      value: ids.contains(entry.id),
                      onChanged: (value) => matcher.setSources(
                        value
                            ? [...ids, entry.id]
                            : ids.where((id) => id != entry.id).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            if (entries.isEmpty) const HyperText('暂无支持歌曲搜索和歌词接口的插件'),
          ],
        );
      }),
    );
  }
}
