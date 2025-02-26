import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
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
  RxList<String> matchSite = RxList();

  @override
  void initState() {
    super.initState();
    plugins.value = ApiFactory.getSearchPlugins();
    matchVip.value = Sp.getBool(Constant.KEY_MATCH_VIP) ?? false;
    matchSite.addAll(Sp.getStringList(Constant.KEY_MATCH_SITE) ?? []);
    sortMatchList();
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Obx(
        () => HyperBackground(
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text("音源匹配")),
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
              SliverGap(12),
              HyperGroup(
                title: Text("将下列站点作为匹配站点"),
                trailing: Text("长按可拖动排序"),
                children: [
                  ReorderableListView.builder(
                    padding: EdgeInsets.all(0),
                    buildDefaultDragHandles: false,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: plugins.length,
                    itemBuilder: (BuildContext context, int index) {
                      var plugin = plugins[index];

                      return Obx(
                        key: ValueKey(index),
                        () => ReorderableDelayedDragStartListener(
                            enabled: matchSite.contains(plugin.package),
                            key: ValueKey(index),
                            index: index,
                            child: CheckboxListTile(
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
                                sortMatchList();
                                Sp.setStringList(Constant.KEY_MATCH_SITE, matchSite.toList());
                                ApiFactory.initMatch();
                              },
                            )),
                      );
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      if (newIndex >= matchSite.length) {
                        newIndex = matchSite.length;
                      }
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = matchSite.removeAt(oldIndex);
                      matchSite.insert(newIndex, item);

                      sortMatchList();
                      Sp.setStringList(Constant.KEY_MATCH_SITE, matchSite);
                      ApiFactory.initMatch();
                    },
                  )
                ],
              ),
              SliverGap(bottom + 16)
            ],
          ),
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

  void sortMatchList() {
    matchSite.toList().reversed.forEach((e) {
      var item = plugins.firstWhere((i) => i.package == e);
      plugins.remove(item);
      plugins.insert(0, item);
    });
  }
}
