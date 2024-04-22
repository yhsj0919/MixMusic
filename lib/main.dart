import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:mix_music/init/app_binding.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/app_theme.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/utils/sp.dart';

import 'main.mapper.g.dart';
import 'player/Player.dart';

const _brandBlue = Color(0xFF1E88E5);
const Set<PointerDeviceKind> _kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Sp.init();
  await Player.init();
  initializeJsonMapper();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    // 沉浸式状态栏（仅安卓）
    statusBarColor: Colors.transparent,
    // 沉浸式导航指示器
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeController theme = Get.put(ThemeController());

    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme lightColorScheme;
      ColorScheme darkColorScheme;
      if (lightDynamic != null && darkDynamic != null) {
        lightColorScheme = lightDynamic.harmonized();
        lightColorScheme = lightColorScheme.copyWith(secondary: _brandBlue);
        darkColorScheme = darkDynamic.harmonized();
        darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);
      } else {
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: _brandBlue,
        );
        darkColorScheme = ColorScheme.fromSeed(
          seedColor: _brandBlue,
          brightness: Brightness.dark,
        );
      }

      return Obx(() => GetMaterialApp(
            title: 'MixMusic',
            //桌面拖动支持
            scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true, dragDevices: _kTouchLikeDeviceTypes),
            debugShowCheckedModeBanner: false,
            initialBinding: AppBinding(),
            theme: ThemeData(
              colorSchemeSeed: theme.customerColor.value ?? lightColorScheme.primary,
              // extensions: [lightCustomColors],
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorSchemeSeed: theme.customerColor.value ?? darkColorScheme.primary,
              // extensions: [darkCustomColors],
            ),
            // builder: appRootWidget,
            //2.注册路由观察者
            getPages: Routes.routes,
            initialRoute: Routes.welcome,
            localizationsDelegates: const [
              //此处
              GlobalMaterialLocalizations.delegate, // uses `flutter_localizations`
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ));
    });
  }
}
