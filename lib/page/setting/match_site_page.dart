import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:mix_music/api/api_factory.dart';
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
    matchVip.value = ApiFactory.getMatchVip();
    plugins.value = ApiFactory.getPlugins().where((element) => element.method?.contains("searchMusic") == true).toList();
    matchSite.addAll(ApiFactory.getMatchSite());
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

                  Sp.setBool(Sp.KEY_MATCH_VIP, value);
                  ApiFactory.matchVip(value);
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
                        value: matchSite.contains(plugin.site),
                        onChanged: (bool? value) {
                          if (value == true) {
                            matchSite.add(plugin.site ?? "");
                          } else {
                            matchSite.remove(plugin.site ?? "");
                          }
                          ApiFactory.setMatchSite(matchSite.value);
                          Sp.setStringList(Sp.KEY_MATCH_SITE, matchSite.toList());
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
