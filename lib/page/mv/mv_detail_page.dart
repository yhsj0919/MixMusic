import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/plugin_controller.dart';
import '../../common/entity/mv.dart';
import '../setting/extension/plugin_logs.dart';
import 'mv_controller.dart';

class MvDetailPage extends StatefulWidget {
  const MvDetailPage({
    super.key,
    required this.plugins,
    required this.resource,
  });
  final PluginController plugins;
  final Mv resource;

  @override
  State<MvDetailPage> createState() => _MvDetailPageState();
}

class _MvDetailPageState extends State<MvDetailPage> {
  late final controller = MvController(widget.plugins, widget.resource);

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: HyperText(widget.resource.title),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
    ),
    body: Obx(
      () => controller.info.when(
        loading: () => const Center(child: HyperText('正在加载…')),
        error: (error, stack) => HyperResult.empty(
          title: 'MV 详情加载失败',
          description: '$error',
          actions: [
            HyperButton.tonal(
              onPressed: controller.load,
              label: const HyperText('重试'),
            ),
          ],
        ),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            HyperText(detail.title),
            if (detail.favorited != null)
              HyperBadge(label: detail.favorited! ? '已收藏' : '未收藏'),
            if (detail.subtitle != null) HyperText(detail.subtitle!),
            if (detail.description case final String description)
              HyperText(description),
            const SizedBox(height: 16),
            HyperText('地址：${detail.url ?? '未返回地址'}'),
            for (final quality in detail.qualities)
              HyperListTile(
                title: HyperText(quality.title),
                subtitle: HyperText(quality.url ?? '未返回地址'),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (controller.supportsFavorite)
                  HyperMenuButton(
                    items: [
                      if (detail.favorited != true)
                        const HyperMenuItem(id: 'favorite', label: '收藏'),
                      if (detail.favorited != false)
                        const HyperMenuItem(id: 'unfavorite', label: '取消收藏'),
                    ],
                    onSelected: (action) => widget.plugins.manage(
                      widget.resource.pluginId,
                      () async {
                        final value = action == 'favorite';
                        await controller.favorite(value);
                        return value ? '已收藏' : '已取消收藏';
                      },
                    ),
                    child: const HyperIcon(Icons.more_horiz),
                  ),
                HyperButton.tonal(
                  onPressed: controller.printAddresses,
                  label: const HyperText('打印地址'),
                ),
                HyperButton.text(
                  onPressed: () => showPluginLogs(
                    context,
                    pluginId: widget.resource.pluginId,
                  ),
                  label: const HyperText('查看插件日志'),
                ),
              ],
            ),
            Obx(
              () => widget.plugins.action.hasError
                  ? HyperText('操作失败：${widget.plugins.action.errorValue}')
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
}
