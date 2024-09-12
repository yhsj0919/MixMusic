import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';

import '../../entity/plugins_info.dart';

class MatchSitePage extends StatefulWidget {
  const MatchSitePage({super.key});

  @override
  State<MatchSitePage> createState() => _MatchSitePageState();
}

class _MatchSitePageState extends State<MatchSitePage> {
  RxBool matchVip = RxBool(false);
  RxList<PluginsInfo> plugins = RxList();
  RxSet<String> matchSite = RxSet();

  @override
  void initState() {
    super.initState();
    plugins.value = ApiFactory.getSearchPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("音源匹配")),
      body: Column(
        children: [
          Obx(() => SwitchListTile(
                title: const Text("音源匹配"),
                subtitle: const Text("从其他站点获取同名音乐播放"),
                value: matchVip.value,
                onChanged: (value) {
                  matchVip.value = value;

                  Sp.setBool(Constant.KEY_MATCH_VIP, value);
                },
              )),
          ListTile(
            title: Text("站点", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
            subtitle: const Text("将下列站点作为匹配站点"),
          ),
          Obx(() => ListView.builder(
                itemCount: plugins.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  var plugin = plugins[index];

                  return Obx(() => CheckboxListTile(
                        title: Text(plugin.name ?? ""),
                        subtitle: Text(plugin.version ?? ""),
                        secondary: AppImage(url: '${plugin.icon}', width: 40, height: 40),
                        value: matchSite.contains(plugin.package ),
                        onChanged: (bool? value) {
                          if (value == true) {
                            matchSite.add(plugin.package  ?? "");
                          } else {
                            matchSite.remove(plugin.package  ?? "");
                          }
                          Sp.setStringList(Constant.KEY_MATCH_SITE, matchSite.toList());
                        },
                      ));
                },
              )),
        ],
      ),
    );
  }

  void changeMatchSite(bool add, String site) {
    if (add) {
      matchSite.add(site);
    } else {
      matchSite.remove(site);
    }
  }
}
