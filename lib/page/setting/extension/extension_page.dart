import 'dart:io';
import 'dart:math';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/home/home_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/plugin_item.dart';
import 'package:tiny_db/tiny_db.dart';

import 'extension_detail_page.dart';

class ExtensionPage extends StatefulWidget {
  const ExtensionPage({super.key});

  @override
  State<ExtensionPage> createState() => _ExtensionPageState();
}

class _ExtensionPageState extends State<ExtensionPage> {
  HomeController home = Get.put(HomeController());

  List<PluginsInfo> plugins = [];
  String? homeSite;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    homeSite = AppDB.getString(Constant.KEY_HOME_SITE);

    getPlugins();
  }

  Future<void> getPlugins() async {
    List<PluginsInfo>? list = await AppDB.getList(Constant.KEY_EXTENSION);
    setState(() {
      plugins = list ?? [];
    });
  }

  Future<void> initPlugins() async {
    await ApiFactory.init();
    home.getData();
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        // 动画图标
        overlayColor: Colors.black,
        // 背景遮罩颜色
        overlayOpacity: 0.3,
        // 背景遮罩透明度
        childMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        childPadding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 设置为方形
        ),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.file_open),
            label: '本地',
            onTap: () async {
              try {
                var result = await FilePicker.pickFiles(
                  dialogTitle: "选择插件",
                  lockParentWindow: true,
                  type: GetPlatform.isDesktop ? FileType.custom : FileType.any,
                  allowedExtensions: GetPlatform.isDesktop ? ["js"] : null,
                );
                if (result != null) {
                  File file = File(result.files.single.path!);
                  var plugins = parseExtension(file.readAsStringSync());
                  if (plugins == null) {
                    showError("插件无效");
                  } else {
                    AppDB.insertOrUpdate(table: Constant.KEY_EXTENSION, doc: JsonMapper.toMap(plugins)!, queryCondition: where("package").equals(plugins.package)).then((v) {
                      getPlugins();
                      initPlugins();
                    });
                  }
                } else {
                  // User canceled the picker
                }

                getPlugins();
              } catch (e) {
                showError('文件异常，可能不存在');
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_link_outlined),
            label: '网络',
            onTap: () {
               Get.toNamed(id: Routes.key,Routes.extensionNet)?.then((v) {
                getPlugins();
                initPlugins();
              });
            },
          ),
        ],
      ),
      body: HyperBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(title: Text("插件")),
            HyperGroup(
              title: Text("已安装"),
              trailing: Text("长按可拖动排序"),
              children: [
                ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plugins.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    var item = plugins[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(index),
                      index: index,
                      child: HyperListTile(
                        key: ValueKey(index),
                        leading: HyperLeading(size: 40, child: AppImage(url: "${item.icon}")),
                        title: "${item.name} ${item.version}",
                        subtitle: "${item.desc}",
                        trailing: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: HyperTrailing(icon: Icons.clear),
                          ),
                          onTap: () async {
                            ///删除设置的首页
                            if (homeSite == item.package) {
                              AppDB.kvRemove(Constant.KEY_HOME_SITE);
                            }
                            deleteExtension(item.package);
                            getPlugins();
                            initPlugins();
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(OpacityRoute(builder: (context) => ExtensionDetailPage(pluginInfo: item)));
                        },
                      ),
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = plugins.removeAt(oldIndex);
                    plugins.insert(newIndex, item);

                    AppDB.replaceAll(table: Constant.KEY_EXTENSION, docs: plugins.map((e) => JsonMapper.toMap(e)!).toList()).then((v) {
                      getPlugins();
                      initPlugins();
                    });
                  },
                ),
              ],
            ),
            SliverGap(bottom + 80),
          ],
        ),
      ),
    );
  }

  Future<void> deleteExtension(String? package) async {
    await AppDB.remove(table: Constant.KEY_EXTENSION, queryCondition: where("package").equals(package));
  }
}
