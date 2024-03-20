import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/sliding_up_panel.dart';

class AppController extends GetxController {
  PanelController panelController = PanelController();
  ScrollController panelScrollController = ScrollController();
  RxDouble position = RxDouble(0);
  RxDouble maxHeight = RxDouble(0);
  RxDouble maxWidth = RxDouble(0);
  RxInt type = RxInt(0);
  RxInt navBarIndex = RxInt(0);
  RxBool showNav = RxBool(true);
  RxBool showPlayBar = RxBool(true);

  RxnString currentRoute = RxnString(Routes.home);

  @override
  void onInit() {
    super.onInit();

    currentRoute.listen((p0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (p0 == Routes.home) {
          showNav.value = true;
        } else {
          showNav.value = false;
        }
      });
    });
    initMatchSite();
  }

  initMatchSite() {
    var matchVip = Sp.getBool(Sp.KEY_MATCH_VIP) ?? false;
    var matchSite = Sp.getStringList(Sp.KEY_MATCH_SITE) ?? [];

    ApiFactory.matchVip(matchVip);
    ApiFactory.setMatchSite(matchSite.toSet());
  }
}
