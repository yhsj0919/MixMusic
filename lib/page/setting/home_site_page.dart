import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/home/home_controller.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';

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
        () => CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text("首页数据"),
            ),
            SliverToBoxAdapter(
              child: ListTile(
                title: Text("站点", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                subtitle: Text("下列站点可展示在首页", style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
            SliverList.builder(
              itemCount: plugins.length,
              itemBuilder: (BuildContext context, int index) {
                var plugin = plugins[index];
                return Obx(
                  () => CommonItem(
                    child: RadioListTile<String?>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(plugin.name ?? ""),
                      subtitle: Text(plugin.version ?? ""),
                      secondary: AppImage(url: '${plugin.icon}', width: 40, height: 40),
                      value: plugin.package,
                      groupValue: homeSite.value,
                      onChanged: (String? value) {
                        Sp.setString(Constant.KEY_HOME_SITE, value ?? "");
                        homeSite.value = value;
                        home.getData();
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
