import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:media_kit/media_kit.dart' as media;
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/app_theme.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/theme/windows_controls.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/db.dart';

import 'main.mapper.g.dart';
import 'page/download/download_controller.dart';
import 'page/timer/timer_close_controller.dart';
import 'player/Player.dart';

const Set<PointerDeviceKind> _kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDB.init();
  await initWindow();
  media.MediaKit.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  await Player.init();
  initializeJsonMapper();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      // 沉浸式状态栏（仅安卓）
      statusBarColor: Colors.transparent,
      // 沉浸式导航指示器
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await ApiFactory.init();
  Get.put(ThemeController());
  Get.put(MusicController());
  Get.put(DownloadController());
  Get.put(TimeCloseController());

  runApp(const MyApp());
}

class MyApp extends fluent.StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return  buildMobile(context);
    // return  buildDesktop(context);
    return GetPlatform.isDesktop ? buildDesktop(context) : buildMobile(context);
  }

  Widget buildMobile(BuildContext context) {
    return GetMaterialApp(
      title: 'MixMusic',
      //桌面拖动支持
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true, dragDevices: _kTouchLikeDeviceTypes),
      debugShowCheckedModeBanner: false,

      // initialBinding: AppBinding(),
      theme: lightTheme,
      darkTheme: darkTheme,
      builder: (_, child) {
        ///如果无法检测到状态栏高度使用默认高度
        var isPaddingCheckError = MediaQuery.of(context).viewPadding.top <= 0 || MediaQuery.of(context).viewPadding.top > 50;

        if (isPaddingCheckError) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(viewPadding: const EdgeInsets.only(top: 24, bottom: 24), padding: const EdgeInsets.only(top: 16, bottom: 24)),
            child: child ?? Container(),
          );
        } else {
          return child ?? Container();
        }
      },
      // builder: appRootWidget,
      //2.注册路由观察者
      getPages: Routes.mobileRoutes,
      initialRoute: Routes.welcome,
      localizationsDelegates: const [
        //此处
        GlobalMaterialLocalizations.delegate, // uses `flutter_localizations`
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        //此处
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
    );
  }

  Widget buildDesktop(BuildContext context) {
    var theme = Get.put(ThemeController());

    return Obx(
      () => fluent.FluentApp.router(
        themeMode: theme.themeMode.value,
        title: 'MixMusic',
        //桌面拖动支持
        scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true, dragDevices: _kTouchLikeDeviceTypes),
        debugShowCheckedModeBanner: false,
        builder: windowsControls,
        theme: fluent.FluentThemeData(brightness: Brightness.light, fontFamily: "Microsoft YaHei"),
        darkTheme: fluent.FluentThemeData(brightness: Brightness.dark, fontFamily: "Microsoft YaHei"),
        routeInformationParser: Routes.desktopRouter.routeInformationParser,
        routerDelegate: Routes.desktopRouter.routerDelegate,
        routeInformationProvider: Routes.desktopRouter.routeInformationProvider,
        localizationsDelegates: [fluent.FluentLocalizations.delegate],
      ),
    );
  }
}
