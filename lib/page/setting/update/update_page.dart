import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update_controller.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});
  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final controller = UpdateController();
  String? openError;

  Future<void> open(Uri url) async {
    setState(() => openError = null);
    try {
      await controller.open(url);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              openError = error is StateError ? error.message : '无法打开链接，请稍后重试',
        );
      }
    }
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HyperScaffold(
    appBar: HyperAppBar(
      title: const HyperText('检查更新'),
      automaticallyImplyLeading: false,
      leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
          ? null
          : HyperIconButton.ghost(
              tooltip: '返回',
              icon: const HyperIcon(Icons.arrow_back),
              onPressed: () => context.go('/settings'),
            ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const HyperText('MixMusic', variant: HyperTextVariant.sectionTitle),
        FutureBuilder<PackageInfo>(
          future: controller.package,
          builder: (context, snapshot) => HyperText(
            snapshot.hasData
                ? '当前版本：${snapshot.data!.version}（${snapshot.data!.buildNumber}）'
                : snapshot.hasError
                ? '无法读取当前版本'
                : '正在读取版本…',
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<void>(
          future: controller.restored,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const HyperText('无法读取更新渠道设置');
            return Obx(
              () => HyperSelect<UpdateChannel>(
                value: controller.channel.value,
                enabled:
                    snapshot.connectionState == ConnectionState.done &&
                    !controller.result.isLoading,
                options: [
                  for (final channel in UpdateChannel.values)
                    HyperSelectOption(value: channel, label: channel.title),
                ],
                onChanged: (value) {
                  if (value != null) controller.setChannel(value);
                },
              ),
            );
          },
        ),
        const HyperText('更新渠道：正式版使用 GitHub Latest；测试版包含预发行版。'),
        const SizedBox(height: 12),
        HyperButton.tonal(
          onPressed: controller.check,
          label: const HyperText('检查更新'),
        ),
        const SizedBox(height: 12),
        Obx(
          () => controller.result.when(
            loading: () => const HyperText('正在检查更新…'),
            error: (error, stack) => HyperText('检查失败：$error'),
            data: (check) {
              if (check == null) return const HyperText('点击检查 GitHub 上的新版本');
              final release = check.release;
              if (release == null) {
                return const HyperText('暂未获取到所选渠道的发布版本，可前往 GitHub 发布页查看');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HyperText(
                    check.available ? '发现新版本：${release.version}' : '当前已是最新版本',
                  ),
                  if (check.available) ...[
                    const SizedBox(height: 12),
                    HyperText(
                      release.title,
                      variant: HyperTextVariant.sectionTitle,
                    ),
                    HyperText(
                      release.notes.isEmpty ? '此版本未提供更新说明' : release.notes,
                    ),
                    const SizedBox(height: 12),
                    for (final asset in release.assets)
                      HyperButton.text(
                        onPressed: () => open(asset.url),
                        label: HyperText(
                          '下载 ${asset.name}（${(asset.size / 1024 / 1024).toStringAsFixed(1)} MB）',
                        ),
                      ),
                    if (release.assets.isEmpty)
                      const HyperText('此版本暂无附件，可前往发布页查看'),
                    HyperButton.text(
                      onPressed: () => open(release.url),
                      label: const HyperText('查看此版本发布页'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        HyperButton.text(
          onPressed: () => open(UpdateController.releasesUrl),
          label: const HyperText('所有 GitHub 版本'),
        ),
        if (openError != null) HyperText(openError!),
      ],
    ),
  );
}
