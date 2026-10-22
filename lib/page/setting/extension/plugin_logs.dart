import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../common/plugin/plugin_controller.dart';

Future<void> showPluginLogs(BuildContext context, {String? pluginId}) {
  final controller = context.lx.find<PluginController>();
  return showHyperDialog<void>(
    context: context,
    builder: (context) => HyperDialog(
      title: HyperText(pluginId == null ? '插件日志' : '$pluginId 日志'),
      scrollable: false,
      content: SizedBox(
        width: 720,
        height: MediaQuery.sizeOf(context).height * .5,
        child: Obx(() {
          final logs = controller.logs.value
              .where((log) => pluginId == null || log.pluginId == pluginId)
              .toList();
          if (logs.isEmpty) {
            return const HyperResult.empty(
              title: '暂无日志',
              description: '插件运行时产生的日志将显示在这里',
            );
          }
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) => HyperListTile(
              title: HyperText(
                '${logs[index].level.toUpperCase()} · ${logs[index].pluginId}',
              ),
              subtitle: HyperText(
                '${logs[index].time.toIso8601String()}\n${logs[index].message}',
              ),
            ),
          );
        }),
      ),
      actions: [
        HyperButton.text(
          onPressed: () => context.pop(),
          label: const HyperText('关闭'),
        ),
        HyperButton.text(
          onPressed: () => controller.logs.value = pluginId == null
              ? []
              : controller.logs.value
                    .where((log) => log.pluginId != pluginId)
                    .toList(),
          label: const HyperText('清空'),
        ),
        HyperButton.tonal(
          onPressed: () => Clipboard.setData(
            ClipboardData(
              text: controller.logs.value
                  .where((log) => pluginId == null || log.pluginId == pluginId)
                  .join('\n'),
            ),
          ),
          label: const HyperText('复制日志'),
        ),
      ],
    ),
  );
}
