import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';
import 'parse_controller.dart';

class ParsePlayList extends StatefulWidget {
  const ParsePlayList({super.key, required this.plugins});
  final PluginController plugins;
  @override
  State<ParsePlayList> createState() => _ParsePlayListState();
}

class _ParsePlayListState extends State<ParsePlayList> {
  late final ParseController controller;
  final input = TextEditingController();
  late final ready = widget.plugins.restored;

  @override
  void initState() {
    super.initState();
    controller = ParseController(widget.plugins);
  }

  @override
  void dispose() {
    input.dispose();
    controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: const HyperText('导入歌单'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
    ),
    body: FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) => Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HyperText(
                    controller.sources.isEmpty
                        ? '没有支持歌单解析的插件'
                        : '支持：${controller.sources.map((entry) => entry.record.name).join('、')}',
                  ),
                  const SizedBox(height: 8),
                  HyperTextField(controller: input, hintText: '粘贴歌单链接或分享内容'),
                  const SizedBox(height: 8),
                  HyperButton.filled(
                    onPressed:
                        controller.result.isLoading ||
                            controller.sources.isEmpty
                        ? null
                        : () => controller.parse(input.text),
                    label: HyperText(
                      controller.result.isLoading ? '正在解析…' : '解析',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: controller.result.when(
                loading: () => const Center(child: HyperText('正在解析…')),
                error: (error, stack) =>
                    HyperResult.empty(title: '解析失败', description: '$error'),
                data: (items) => items.isEmpty
                    ? const HyperResult.empty(title: '暂无解析结果')
                    : ListView(
                        children: [
                          for (final item in items)
                            HyperListTile(
                              leading: const HyperIcon(Icons.queue_music),
                              title: HyperText(item.title),
                              subtitle: HyperText(
                                item.subtitle ?? item.pluginId,
                              ),
                              onTap: () =>
                                  context.push('/playlist', extra: item),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
