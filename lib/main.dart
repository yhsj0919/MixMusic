import 'package:flutter/material.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page/setting/setting_controller.dart';
import 'common/plugin/plugin_controller.dart';
import 'common/player/player_controller.dart';
import 'common/download/download_controller.dart';
import 'common/local/local_music_controller.dart';
import 'common/local/local_music_api.dart';
import 'route/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(MainApp(preferences: preferences));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.preferences});
  final SharedPreferences? preferences;
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final controllers = LxContainer();
  late final settings = controllers.put(
    () => SettingController(preferences: widget.preferences),
  );
  late final router = createRouter(settings);

  @override
  void dispose() {
    router.dispose();
    controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LxScope(
      container: controllers,
      disposeContainer: false,
      bindings: (scope) {
        scope.put(() => PluginController(preferences: widget.preferences));
        scope.put(() => LocalMusicController(preferences: widget.preferences));
        final plugins = controllers.find<PluginController>();
        plugins.builtins[LocalMusicController.pluginId] = LocalMusicApi(
          plugins.manager,
        );
        scope.put(
          () => PlayerController(
            scope.find<PluginController>(),
            preferences: widget.preferences,
          ),
        );
        scope.put(
          () => DownloadController(
            scope.find<PluginController>(),
            cache: scope.find<PlayerController>().cache,
            preferences: widget.preferences,
          ),
        );
      },
      child: MaterialApp.router(
        title: 'MixMusic',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (context, child) => HyperDeviceDetector(
          builder: (context, device, child) => Obx(
            () => HyperTheme(
              data: settings.darkMode.value
                  ? HyperThemeData.dark()
                  : HyperThemeData.light(),
              child: child!,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
