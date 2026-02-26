import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/app_playing/phone_home_playing.dart';
import 'package:mix_music/route/routes.dart';

class MobileHomeMain extends StatefulWidget {
  const MobileHomeMain({super.key});

  @override
  State<MobileHomeMain> createState() => _MobileHomeMainState();
}

class _MobileHomeMainState extends State<MobileHomeMain> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (Get.global(Routes.key).currentState?.canPop() == true) {
          Get.back(id: Routes.key);
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            !context.isLandscape ? Container() : Container(width: 400, child: PhoneHomePlaying()),
            Expanded(
              child: Navigator(
                key: Get.nestedKey(Routes.key),
                // initialRoute: Routes.main,
                reportsRouteUpdateToEngine: true,
                onGenerateRoute: (setting) {
                  if (setting.name == Routes.main && Navigator.canPop(context)) {
                    Get.back(id: Routes.key);
                  }
                  // mainController.currentRoute = setting.name;
                  return Routes.getMobileRoute(setting);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
