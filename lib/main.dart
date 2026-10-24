import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
import 'common/database/app_database.dart';
import 'common/history/playback_history_store.dart';
import 'common/history/player_history.dart';
import 'common/download/download_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final directory = kIsWeb ? null : await getApplicationSupportDirectory();
  runApp(
    MainApp(
      preferences: preferences,
      databasePath: directory == null
          ? 'mix_music.sqlite'
          : '${directory.path}/mix_music.sqlite',
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.preferences, this.databasePath});
  final SharedPreferences? preferences;
  final String? databasePath;
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  final controllers = LxContainer();
  late final settings = controllers.put(
    () => SettingController(preferences: widget.preferences),
  );
  late final router = createRouter(settings);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        controllers.contains<PlayerController>()) {
      unawaited(controllers.find<PlayerController>().session.save());
    }
    if (state != AppLifecycleState.resumed &&
        controllers.contains<DownloadController>()) {
      unawaited(controllers.find<DownloadController>().session?.save());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        if (widget.databasePath case final path?) {
          scope.put(() => AppDatabase(path));
          scope.put(() => DownloadStore(scope.find<AppDatabase>()));
        }
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
            store: widget.databasePath == null
                ? null
                : scope.find<DownloadStore>(),
          ),
        );
        if (widget.databasePath != null) {
          scope.put(() => PlaybackHistoryStore(scope.find<AppDatabase>()));
          scope.put(
            () => PlayerHistory(
              scope.find<PlayerController>(),
              scope.find<PlaybackHistoryStore>(),
            ),
          );
        }
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
