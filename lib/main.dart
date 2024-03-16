import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/app_main/app_main_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/app_theme.dart';
import 'package:mix_music/utils/sp.dart';

import 'main.mapper.g.dart';
import 'player/Player.dart';

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MixMusic',
      //桌面拖动支持
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true, dragDevices: _kTouchLikeDeviceTypes),
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      theme: platformBrightness == Brightness.dark ? darkTheme : lightTheme,
      // builder: appRootWidget,
      //2.注册路由观察者
      getPages: Routes.routes,
      initialRoute: Routes.main,
      localizationsDelegates: const [
        //此处
        GlobalMaterialLocalizations.delegate, // uses `flutter_localizations`
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
