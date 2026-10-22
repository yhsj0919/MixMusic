import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../common/plugin/plugin_controller.dart';
import '../../../common/player/player_controller.dart';
import '../../../common/entity/plugin_account.dart';
import 'plugin_logs.dart';

class ExtensionPage extends StatefulWidget {
  const ExtensionPage({super.key});

  @override
  State<ExtensionPage> createState() => _ExtensionPageState();
}

class _ExtensionPageState extends State<ExtensionPage> {
  Future<void>? ready;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ready ??= context.lx.find<PluginController>().loadAccounts();
  }

  Future<void> openRoute(String id, String route) async {
    final plugins = context.lx.find<PluginController>();
    await context.push(
      Uri(
        path: '/settings/extensions/ui',
        queryParameters: {'plugin': id, 'route': route},
      ).toString(),
    );
    if (mounted) await plugins.loadAccount(id);
  }

  Future<void> menuAction(JsExtensionManagerEntry entry, String action) async {
    final plugins = context.lx.find<PluginController>();
    final player = context.lx.find<PlayerController>();
    switch (action) {
      case 'login':
        await openRoute(entry.id, plugins.authenticationRoute(entry.id)!);
        return;
      case 'refresh':
        await plugins.loadAccount(entry.id);
        return;
      case 'select':
        await plugins.selectSource(entry.id);
        if (mounted) context.go('/');
        return;
      case 'toggle':
        await plugins.manage(entry.id, () async {
          final enabled = entry.state != JsExtensionManagerState.enabled;
          if (!enabled) await player.stopSource(entry.id);
          await plugins.setEnabled(entry.id, enabled);
          return enabled ? '插件已启用' : '插件已停用';
        });
        return;
      case 'logs':
        showPluginLogs(context, pluginId: entry.id);
        return;
      case 'remove':
        await remove(context, entry);
        return;
      default:
        await openRoute(entry.id, action.substring('route:'.length));
    }
  }

  Widget accountInfo(PluginAccount account) => HyperListTile(
    leading: account.pic == null
        ? null
        : Image.network(account.pic!, width: 40, height: 40),
    title: HyperText(
      account.status == 'signedIn' ? account.name : account.message,
    ),
    subtitle: account.status != 'signedIn'
        ? null
        : HyperText(
            [
              if (account.id != null) '账号：${account.id}',
              switch (account.isVip) {
                true => 'VIP',
                false => '非 VIP',
                null => 'VIP 状态未知',
              },
              if (account.vipEndTime != null)
                '到期时间：${account.vipEndTime.toString().split('.').first}',
            ].join('\n'),
          ),
  );

  Future<void> pickZip(
    BuildContext context,
    PluginController plugins,
  ) => plugins.manage('installer', () async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (files.isEmpty) return '已取消安装';
    final package = await JsExtensionPackage.zipBytes(
      await files.single.readAsBytes(),
    );
    final manifest = JsExtensionManifest.parse(package.manifestSource);
    await plugins.restored;
    await plugins.manager.inspectPackage(package);
    if (!context.mounted) return '已取消安装';
    final existing = plugins.manager.find(manifest.id);
    final confirmed = await showHyperDialog<bool>(
      context: context,
      builder: (context) => HyperDialog(
        title: HyperText(existing == null ? '安装插件' : '更新插件'),
        content: HyperText(
          '${manifest.name}\n${manifest.id}\n版本：${manifest.version}\n${manifest.description}\n权限：${manifest.permissions.join('、')}',
        ),
        actions: [
          HyperButton.text(
            onPressed: () => context.pop(false),
            label: const HyperText('取消'),
          ),
          HyperButton.filled(
            onPressed: () => context.pop(true),
            label: HyperText(existing == null ? '安装' : '更新 / 覆盖'),
          ),
        ],
      ),
    );
    if (confirmed != true) return '已取消安装';
    await plugins.install(package);
    return '${manifest.name} 安装完成';
  });

  Future<void> remove(
    BuildContext context,
    JsExtensionManagerEntry entry,
  ) async {
    final plugins = context.lx.find<PluginController>();
    final player = context.lx.find<PlayerController>();
    final clearStorage = await showHyperDialog<bool>(
      context: context,
      builder: (context) => HyperDialog(
        title: HyperText('卸载 ${entry.record.name}'),
        content: const HyperText(
          '卸载会移除插件包。可保留登录和设置以便重装，或同时删除全部插件数据。不会删除你选择的原始 ZIP 文件。',
        ),
        actions: [
          HyperButton.text(
            onPressed: () => context.pop(),
            label: const HyperText('取消'),
          ),
          HyperButton.tonal(
            onPressed: () => context.pop(false),
            label: const HyperText('卸载，保留数据'),
          ),
          HyperButton.filled(
            onPressed: () => context.pop(true),
            label: const HyperText('彻底删除'),
          ),
        ],
      ),
    );
    if (clearStorage == null) return;
    await plugins.manage(entry.id, () async {
      await player.stopSource(entry.id);
      await plugins.uninstall(entry.id, clearStorage: clearStorage);
      return clearStorage ? '插件及数据已删除' : '插件已卸载，数据已保留';
    });
  }

  @override
  Widget build(BuildContext context) {
    final plugins = context.lx.find<PluginController>();
    return HyperScaffold(
      appBar: HyperAppBar.large(
        title: const HyperText('插件管理'),
        automaticallyImplyLeading: false,
        leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
            ? null
            : HyperIconButton.ghost(
                key: const ValueKey('page-back'),
                tooltip: '返回',
                onPressed: () => context.go('/settings'),
                icon: const HyperIcon(Icons.arrow_back_rounded),
              ),
      ),
      body: FutureBuilder(
        future: ready,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return HyperResult.empty(
              title: '插件恢复失败',
              description: '${snapshot.error}',
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: HyperText('正在恢复插件…'));
          }
          return Obx(
            () => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                HyperButton.filled(
                  onPressed: plugins.action.isLoading
                      ? null
                      : () => pickZip(context, plugins),
                  label: const HyperText('从 ZIP 安装'),
                ),
                const SizedBox(height: 12),
                if (plugins.action.isLoading) const HyperText('正在处理…'),
                if (plugins.action.hasError)
                  HyperText('操作失败：${plugins.action.errorValue}'),
                if (plugins.action.hasData) HyperText(plugins.action.value!),
                if (plugins.extensions.value.isEmpty)
                  const HyperResult.empty(
                    title: '尚未安装插件',
                    description: '选择 ZIP 插件包开始安装',
                  ),
                for (final entry in plugins.extensions.value) ...[
                  const SizedBox(height: 12),
                  HyperCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HyperListTile(
                          title: HyperText(entry.record.name),
                          subtitle: HyperText(
                            '${entry.id}\nv${entry.version} · ${switch (entry.state) {
                              JsExtensionManagerState.enabled => '已启用',
                              JsExtensionManagerState.disabled => '已停用',
                              JsExtensionManagerState.broken => '恢复失败',
                            }}${entry.error == null ? '' : '\n${entry.error}'}',
                          ),
                          trailing: HyperMenuButton(
                            enabled: !plugins.action.isLoading,
                            onSelected: (action) => menuAction(entry, action),
                            items: [
                              if (plugins.authenticationRoute(entry.id) != null)
                                HyperMenuItem(
                                  id: 'login',
                                  label: '登录 / 账号管理',
                                  enabled:
                                      entry.state ==
                                      JsExtensionManagerState.enabled,
                                ),
                              if (entry
                                      .installed
                                      ?.extension
                                      .service
                                      ?.publicExports
                                      .contains('getAccount') ??
                                  false)
                                HyperMenuItem(
                                  id: 'refresh',
                                  label: '刷新账号信息',
                                  enabled:
                                      entry.state ==
                                      JsExtensionManagerState.enabled,
                                ),
                              for (final route
                                  in entry
                                          .installed
                                          ?.extension
                                          .ui
                                          ?.routes
                                          .entries ??
                                      const <
                                        MapEntry<String, JsExtensionRoute>
                                      >[])
                                if (route.key !=
                                    plugins.authenticationRoute(entry.id))
                                  HyperMenuItem(
                                    id: 'route:${route.key}',
                                    label: route.value.title ?? route.key,
                                    enabled:
                                        entry.state ==
                                        JsExtensionManagerState.enabled,
                                  ),
                              HyperMenuItem(
                                id: 'select',
                                label: '设为首页展示',
                                enabled:
                                    entry.state ==
                                    JsExtensionManagerState.enabled,
                              ),
                              HyperMenuItem(
                                id: 'toggle',
                                label:
                                    entry.state ==
                                        JsExtensionManagerState.enabled
                                    ? '停用'
                                    : '启用',
                              ),
                              const HyperMenuItem(id: 'logs', label: '日志'),
                              const HyperMenuItem(
                                id: 'remove',
                                label: '卸载 / 删除',
                              ),
                            ],
                            child: const HyperIcon(Icons.more_horiz),
                          ),
                        ),
                        if (plugins.accounts.value[entry.id]
                            case final account?)
                          accountInfo(account),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
