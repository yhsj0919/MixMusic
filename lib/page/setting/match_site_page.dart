import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

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
    matchVip.value = Sp.getBool(Constant.KEY_MATCH_VIP) ?? false;
    matchSite.addAll(Sp.getStringList(Constant.KEY_MATCH_SITE) ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => CustomScrollView(
          slivers: [
            HyperAppbar(title: "音源匹配"),
            HyperGroup(
              children: [
                Obx(
                  () => SwitchListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text("音源匹配"),
                    subtitle: const Text("从其他站点获取同名音乐播放"),
                    value: matchVip.value,
                    onChanged: (value) {
                      matchVip.value = value;
                      Sp.setBool(Constant.KEY_MATCH_VIP, value);

                      ApiFactory.initMatch();
                    },
                  ),
                )
              ],
            ),
            HyperGroup(
              title: "将下列站点作为匹配站点",
              children: [
                ListView.builder(
                  padding: EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: plugins.length,
                  itemBuilder: (BuildContext context, int index) {
                    var plugin = plugins[index];

                    return Obx(
                      () => CheckboxListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(plugin.name ?? ""),
                        subtitle: Text(plugin.version ?? ""),
                        secondary: HyperLeading(
                          size: 40,
                          child: AppImage(url: '${plugin.icon}', width: 40, height: 40),
                        ),
                        value: matchSite.contains(plugin.package),
                        onChanged: (bool? value) {
                          if (value == true) {
                            matchSite.add(plugin.package ?? "");
                          } else {
                            matchSite.remove(plugin.package ?? "");
                          }
                          Sp.setStringList(Constant.KEY_MATCH_SITE, matchSite.toList());
                          ApiFactory.initMatch();
                        },
                      ),
                    );
                  },
                )
              ],
            ),
          ],
        ),
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
