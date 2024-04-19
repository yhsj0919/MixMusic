import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';

import '../../entity/plugins_info.dart';
import '../api_controller.dart';

class HomeSitePage extends StatefulWidget {
  const HomeSitePage({super.key});

  @override
  State<HomeSitePage> createState() => _HomeSitePageState();
}

class _HomeSitePageState extends State<HomeSitePage> {
  ApiController controller = Get.put(ApiController());

  RxList<PluginsInfo> plugins = RxList();
  RxnString homeSite = RxnString();

  @override
  void initState() {
    super.initState();
    plugins.value = controller.recPlugins;
    homeSite.value = Sp.getString(Sp.KEY_HOME_SITE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("首页数据")),
      body: Column(
        children: [
          ListTile(
            title: Text("站点", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
            subtitle: const Text("下列站点可展示在首页"),
          ),
          Obx(() => ListView.builder(
                itemCount: plugins.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  var plugin = plugins[index];

                  return Obx(() => RadioListTile<String?>(
                        title: Text(plugin.name ?? ""),
                        subtitle: Text(plugin.version ?? ""),
                        secondary: AppImage(url: '${plugin.icon}', width: 40, height: 40),
                        value: plugin.site,
                        groupValue: homeSite.value,
                        onChanged: (String? value) {
                          Sp.setString(Sp.KEY_HOME_SITE, value ?? "");
                          homeSite.value = value;
                        },
                      ));
                },
              )),
        ],
      ),
    );
  }
}
