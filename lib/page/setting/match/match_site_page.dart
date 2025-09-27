import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

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
    matchVip.value = AppDB.getBool(Constant.KEY_MATCH_VIP) ?? false;
    AppDB.getStringList(Constant.KEY_MATCH_SITE).then((value) {
      matchSite.addAll(value);
      sortMatchList();
    });
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
                        AppDB.setBool(Constant.KEY_MATCH_VIP, value);

                        ApiFactory.initMatch();
                      },
                    ),
                  ),
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
                            secondary: HyperLeading(size: 40, child: AppImage(url: '${plugin.icon}', width: 40, height: 40)),
                            value: matchSite.contains(plugin.package),
                            onChanged: (bool? value) {
                              if (value == true) {
                                matchSite.add(plugin.package ?? "");
                              } else {
                                matchSite.removeWhere((vv) => vv == (plugin.package ?? ""));
                              }
                              sortMatchList();
                              AppDB.insertStringList(Constant.KEY_MATCH_SITE, matchSite.toList());
                              ApiFactory.initMatch();
                            },
                          ),
                        ),
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
                      AppDB.insertStringList(Constant.KEY_MATCH_SITE, matchSite.toList());
                      ApiFactory.initMatch();
                    },
                  ),
                ],
              ),
              SliverGap(bottom + 16),
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
    print(matchSite);
    matchSite.toList().reversed.forEach((e) {
      var item = plugins.firstWhereOrNull((i) => i.package == e);
      if (item != null) {
        plugins.remove(item);
        plugins.insert(0, item);
      }
    });
  }
}
