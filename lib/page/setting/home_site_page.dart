import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/home/home_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

import '../../entity/plugins_info.dart';

class HomeSitePage extends StatefulWidget {
  const HomeSitePage({super.key});

  @override
  State<HomeSitePage> createState() => _HomeSitePageState();
}

class _HomeSitePageState extends State<HomeSitePage> {
  HomeController home = Get.put(HomeController());
  RxList<PluginsInfo> plugins = RxList();
  RxnString homeSite = RxnString();
  ThemeController theme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    plugins.value = ApiFactory.getRecPlugins();
    homeSite.value = Sp.getString(Constant.KEY_HOME_SITE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => HyperBackground(
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text("首页数据"),
              ),
              HyperGroup(
                title: Text("下列站点可展示在首页"),
                children: [
                  ListView.builder(
                    padding: EdgeInsets.all(0),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: plugins.length,
                    itemBuilder: (BuildContext context, int index) {
                      var plugin = plugins[index];
                      return Obx(
                        () => RadioListTile<String?>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(plugin.name ?? ""),
                          subtitle: Text(plugin.version ?? ""),
                          secondary: HyperLeading(
                            child: AppImage(url: '${plugin.icon}'),
                          ),
                          value: plugin.package,
                          groupValue: homeSite.value,
                          onChanged: (String? value) {
                            Sp.setString(Constant.KEY_HOME_SITE, value ?? "");
                            homeSite.value = value;
                            home.getData();
                            theme.refreshMainColor();
                          },
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
