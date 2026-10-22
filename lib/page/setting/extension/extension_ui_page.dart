import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../common/plugin/plugin_controller.dart';

class ExtensionUiPage extends StatelessWidget {
  const ExtensionUiPage({
    super.key,
    required this.pluginId,
    required this.route,
  });
  final String pluginId;
  final String route;

  @override
  Widget build(BuildContext context) {
    final entry = context.lx.find<PluginController>().manager.find(pluginId);
    final installed = entry?.installed;
    return HyperScaffold(
      appBar: HyperAppBar(
        title: HyperText(
          installed?.extension.ui?.routes[route]?.title ??
              entry?.record.name ??
              '插件页面',
        ),
        automaticallyImplyLeading: false,
        leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
            ? null
            : HyperIconButton.ghost(
                key: const ValueKey('page-back'),
                tooltip: '返回',
                onPressed: () => context.go('/settings/extensions'),
                icon: const HyperIcon(Icons.arrow_back_rounded),
              ),
      ),
      body: installed == null || entry!.state != JsExtensionManagerState.enabled
          ? const HyperResult.empty(title: '插件未启用')
          : JsExtensionView.route(session: installed.session, route: route),
    );
  }
}
