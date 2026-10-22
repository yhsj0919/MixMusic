import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/download/download_controller.dart';
import '../../common/entity/music_download.dart';
import '../../common/download/download_collection.dart';
import '../../common/queue/hyper_queue_entry.dart';
import '../setting/extension/plugin_logs.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key, required this.controller});

  final DownloadController controller;

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: const HyperText('下载'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              icon: const HyperIcon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/settings'),
            ),
      actions: [
        HyperIconButton.ghost(
          tooltip: '下载日志',
          icon: const HyperIcon(Icons.bug_report_outlined),
          onPressed: () => showPluginLogs(context, pluginId: 'download'),
        ),
      ],
    ),
    body: NotificationListener<ScrollNotification>(
      onNotification: (event) {
        if (event.depth == 0 &&
            event.metrics.extentAfter < 240 &&
            (event is ScrollUpdateNotification ||
                event is OverscrollNotification)) {
          controller.loadMore();
        }
        return false;
      },
      child: Obx(() {
        final entries = controller.entries;
        final count = controller.tasks.value.length;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: entries.length + 1,
          itemBuilder: (context, index) {
            if (index > 0) {
              final entry = entries[index - 1];
              return entry.source == null
                  ? _task(entry.item!)
                  : _collection(entry);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HyperListTile(
                  title: const HyperText('下载目录'),
                  subtitle: HyperText(
                    controller.selectedDirectory.value.isEmpty
                        ? '默认：应用文档目录/MixMusic/downloads'
                        : controller.selectedDirectory.value,
                  ),
                  trailing: HyperButton.tonal(
                    label: const HyperText('选择文件夹'),
                    onPressed: controller.selectDirectory,
                  ),
                ),
                HyperListTile(
                  title: const HyperText('文件夹整理'),
                  subtitle: HyperText(controller.grouping.value.label),
                  trailing: const HyperIcon(Icons.chevron_right),
                  onTap: () async {
                    final value = await showHyperDialog<DownloadGrouping>(
                      context: context,
                      builder: (context) => HyperDialog(
                        title: const HyperText('文件夹整理'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final item in DownloadGrouping.values)
                              HyperListTile(
                                title: HyperText(item.label),
                                onTap: () => context.pop(item),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (value != null) await controller.setGrouping(value);
                  },
                ),
                const HyperText('按歌手取第一位；按歌单／专辑仅用于对应的批量下载。名称缺失或分类目录创建失败时放根目录。'),
                const HyperText('目录与分类在加入任务时确定，不移动已有文件。配置自动保存，下载任务暂不持久化。'),
                if (controller.directoryError.value.isNotEmpty)
                  HyperText(controller.directoryError.value),
                HyperText('共 $count 个已展开任务。执行时获取地址，移除任务保留文件。'),
                HyperListTile(
                  title: const HyperText('自动重试次数'),
                  subtitle: HyperText(
                    '失败后重试 ${controller.retryCount.value} 次，最多尝试 ${controller.retryCount.value + 1} 次；0 为不重试',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HyperIconButton.ghost(
                        tooltip: '减少',
                        icon: const HyperIcon(Icons.remove),
                        onPressed: controller.retryCount.value == 0
                            ? null
                            : () => controller.setRetryCount(
                                controller.retryCount.value - 1,
                              ),
                      ),
                      HyperText('${controller.retryCount.value}'),
                      HyperIconButton.ghost(
                        tooltip: '增加',
                        icon: const HyperIcon(Icons.add),
                        onPressed: () => controller.setRetryCount(
                          controller.retryCount.value + 1,
                        ),
                      ),
                    ],
                  ),
                ),
                HyperListTile(
                  title: const HyperText('批量下载允许匹配音源'),
                  subtitle: const HyperText('原音源不可用时尝试所选音源；当前播放的匹配版本始终按实际来源下载'),
                  trailing: HyperSwitch(
                    value: controller.allowMatch.value,
                    onChanged: controller.setAllowMatch,
                  ),
                ),
              ],
            );
          },
        );
      }),
    ),
  );

  Widget _collection(HyperQueueEntry<MusicDownload> entry) {
    final group = entry.source!.key as DownloadCollection;
    final tasks = controller.hyperQueue.itemsIn(group);
    final unfinished =
        group.collection.hasMore.value ||
        tasks.any(
          (task) => [
            DownloadState.waiting,
            DownloadState.resolving,
            DownloadState.downloading,
            DownloadState.retrying,
          ].contains(task.state),
        );
    final failed = tasks.any((task) => task.state == DownloadState.failed);
    return HyperListTile(
      leading: const HyperIcon(Icons.queue_music_rounded),
      title: HyperText(group.collection.resource.title),
      subtitle: HyperText(
        '${controller.collectionStatus(group)} · 音质 ${group.quality ?? '默认'}${entry.source!.error.value.isEmpty ? '' : '\n${entry.source!.error.value}'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!group.cancelled.value && group.collection.hasMore.value)
            HyperIconButton.ghost(
              tooltip: '查看更多歌曲',
              icon: const HyperIcon(Icons.expand_more),
              onPressed: () => controller.loadMore(key: group, retry: true),
            ),
          if (entry.suspended || failed)
            HyperIconButton.ghost(
              tooltip: '重试失败或恢复',
              icon: const HyperIcon(Icons.refresh),
              onPressed: () => controller.retryCollection(group),
            ),
          if (!entry.suspended && unfinished)
            HyperIconButton.ghost(
              tooltip: '跳过此来源',
              icon: const HyperIcon(Icons.skip_next_rounded),
              onPressed: () => controller.skipCollection(group),
            ),
          if (!group.cancelled.value && unfinished)
            HyperIconButton.ghost(
              tooltip: '取消此来源',
              icon: const HyperIcon(Icons.close_rounded),
              onPressed: () => controller.cancelCollection(group),
            ),
        ],
      ),
    );
  }

  Widget _task(MusicDownload task) => HyperListTile(
    title: HyperText(task.song.title),
    subtitle: HyperText(
      '${switch (task.state) {
        DownloadState.waiting => '等待下载',
        DownloadState.resolving => '正在获取地址',
        DownloadState.downloading => task.total > 0 ? '${(task.received * 100 / task.total).toStringAsFixed(0)}%' : '${task.received ~/ 1024} KB',
        DownloadState.retrying => '等待重试（已尝试 ${task.attempts} 次）',
        DownloadState.complete => '已完成：${task.path}',
        DownloadState.cancelled => '已取消',
        DownloadState.failed => task.error ?? '下载失败',
      }} · 音质 ${task.song.playQuality ?? '默认'}',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if ([
          DownloadState.waiting,
          DownloadState.resolving,
          DownloadState.downloading,
          DownloadState.retrying,
        ].contains(task.state))
          HyperIconButton.ghost(
            tooltip: '取消',
            icon: const HyperIcon(Icons.close),
            onPressed: () => controller.cancel(task),
          ),
        if ([
          DownloadState.failed,
          DownloadState.cancelled,
        ].contains(task.state))
          HyperIconButton.ghost(
            tooltip: '重试',
            icon: const HyperIcon(Icons.refresh),
            onPressed: () => controller.retry(task),
          ),
        if ([
          DownloadState.complete,
          DownloadState.failed,
          DownloadState.cancelled,
        ].contains(task.state))
          HyperIconButton.ghost(
            tooltip: '移除任务',
            icon: const HyperIcon(Icons.remove_circle_outline),
            onPressed: () => controller.remove(task),
          ),
      ],
    ),
  );
}
