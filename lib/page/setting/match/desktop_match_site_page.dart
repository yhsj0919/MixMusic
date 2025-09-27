import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

class DesktopMatchSitePage extends StatefulWidget {
  const DesktopMatchSitePage({super.key});

  @override
  State<DesktopMatchSitePage> createState() => _DesktopMatchSitePageState();
}

class _DesktopMatchSitePageState extends State<DesktopMatchSitePage> {
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

    return ScaffoldPage(
      header: PageHeader(
        title: Text("音源匹配"),
        leading: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
          child: IconButton(
            icon: Icon(FluentIcons.back),
            onPressed: () {
              context.pop();
            },
          ),
        ),
      ),
      content: Obx(
        () => CustomScrollView(
          slivers: [
            FluentGroup(
              children: [
                Obx(
                  () => FluentListTile(
                    title: "音源匹配",
                    subtitle: "从其他站点获取同名音乐播放",
                    trailing: ToggleSwitch(
                      checked: matchVip.value,
                      onChanged: (bool value) {
                        matchVip.value = value;
                        AppDB.setBool(Constant.KEY_MATCH_VIP, value);
                        ApiFactory.initMatch();
                      },
                    ),
                    onTap: () {
                      matchVip.value = !matchVip.value;
                      AppDB.setBool(Constant.KEY_MATCH_VIP, matchVip.value);
                      ApiFactory.initMatch();
                    },
                  ),
                ),
              ],
            ),
            SliverGap(12),
            FluentGroup(
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
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: FluentTheme.of(context).scaffoldBackgroundColor,
                            border: Border.all(
                              color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                              width: 1, // 边框宽度
                            ),
                            borderRadius: BorderRadius.circular(5), // 圆角半径
                          ),
                          child: ListTile.selectable(
                            selectionMode: ListTileSelectionMode.multiple,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),

                            margin: EdgeInsets.zero,
                            title: Text(plugin.name ?? ""),
                            subtitle: Text(plugin.version ?? ""),
                            leading: AppImage(url: '${plugin.icon}', width: 40, height: 40),
                            selected: matchSite.contains(plugin.package),
                            onSelectionChange: (bool? value) {
                              if (value == true) {
                                matchSite.add(plugin.package ?? "");
                              } else {
                                matchSite.remove(plugin.package ?? "");
                              }
                              sortMatchList();
                              AppDB.insertStringList(Constant.KEY_MATCH_SITE, matchSite.toList());
                              ApiFactory.initMatch();
                            },
                          ),
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
      var item = plugins.firstWhereOrNull((i) => i.package == e);
      plugins.remove(item);
      if (item != null) {
        plugins.insert(0, item);
      }
    });
  }
}
