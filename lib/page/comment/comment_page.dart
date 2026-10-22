import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/song.dart';
import '../../common/plugin/plugin_controller.dart';
import 'comment_controller.dart';

class CommentPage extends StatefulWidget {
  const CommentPage({super.key, required this.plugins, required this.song});
  final PluginController plugins;
  final Song song;
  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  late final CommentController controller;
  @override
  void initState() {
    super.initState();
    controller = CommentController(widget.plugins, widget.song);
    controller.loadMore();
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: HyperText('${widget.song.title} · 评论'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
      actions: [
        HyperIconButton.ghost(
          tooltip: '刷新',
          icon: const HyperIcon(Icons.refresh),
          onPressed: controller.refresh,
        ),
      ],
    ),
    body: Obx(() {
      final loading = controller.loading.value;
      final error = controller.error.value;
      final hasMore = controller.hasMore.value;
      return Column(
        children: [
          if (controller.categories.value.isNotEmpty ||
              controller.total.value != null)
            Wrap(
              children: [
                for (final item in controller.categories.value)
                  HyperButton.text(
                    onPressed: controller.isSelected(item['id'])
                        ? null
                        : () => controller.selectCategory(item['id']),
                    label: HyperText(item['title'] as String),
                  ),
                if (controller.total.value != null)
                  HyperText('${controller.total.value} 条'),
              ],
            ),
          Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (event) {
                if (event.depth == 0 &&
                    event.metrics.extentAfter < 240 &&
                    controller.error.value.isEmpty) {
                  controller.loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.items.value.length + 1,
                itemBuilder: (context, index) {
                  if (index < controller.items.value.length) {
                    final item = controller.items.value[index];
                    return HyperListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HyperText(item.userName),
                          HyperText(item.content),
                        ],
                      ),
                      subtitle: HyperText(
                        [
                          if (item.time != null)
                            DateTime.fromMillisecondsSinceEpoch(item.time!)
                                .toLocal()
                                .toString()
                                .split('.')
                                .first,
                          '${item.likes} 赞',
                        ].join(' · '),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      if (loading)
                        const HyperText('正在加载…')
                      else if (error.isNotEmpty) ...[
                        HyperText('加载失败：$error'),
                        HyperButton.text(
                          onPressed: controller.loadMore,
                          label: const HyperText('重试'),
                        ),
                      ] else if (controller.items.value.isEmpty)
                        const HyperResult.empty(title: '暂无评论')
                      else if (hasMore)
                        HyperButton.text(
                          onPressed: controller.loadMore,
                          label: const HyperText('加载更多'),
                        )
                      else
                        const HyperText('已显示当前可用评论'),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    }),
  );
}
