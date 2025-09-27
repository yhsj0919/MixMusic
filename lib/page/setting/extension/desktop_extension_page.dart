import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/home/home_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_list_tile.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:tiny_db/tiny_db.dart';

class DesktopExtensionPage extends StatefulWidget {
  const DesktopExtensionPage({super.key});

  @override
  State<DesktopExtensionPage> createState() => _DesktopExtensionPageState();
}

class _DesktopExtensionPageState extends State<DesktopExtensionPage> {
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
    return ScaffoldPage(
      header: PageHeader(
        title: Text('插件'),
        leading: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
          child: IconButton(
            icon: Icon(FluentIcons.back),
            onPressed: () {
              context.pop();
            },
          ),
        ),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              onPressed: () async {
                try {
                  var result = await FilePicker.platform.pickFiles(
                    dialogTitle: "选择插件",
                    lockParentWindow: true,
                    type: GetPlatform.isDesktop ? FileType.custom : FileType.any,
                    allowedExtensions: GetPlatform.isDesktop ? ["js"] : null,
                  );
                  if (result != null) {
                    File file = File(result.files.single.path!);
                    var plugins = parseExtension(file.readAsStringSync());
                    if (plugins == null) {
                      showFluentError(context, "插件无效");
                    } else {
                      AppDB.insertOrUpdate(table: Constant.KEY_EXTENSION, doc: JsonMapper.toMap(plugins)!, queryCondition: where("package").equals(plugins.package)).then((
                        v,
                      ) async {
                        showFluentInfo(context, '${plugins.name}，安装成功');

                        getPlugins();
                        initPlugins();
                      });
                    }
                  }
                  getPlugins();
                } catch (e) {
                  showFluentError(context, '文件异常，可能不存在');
                }
              },
              child: Text('本地安装'),
            ),
            Container(width: 8),
            Button(
              onPressed: () {
                context.push(Routes.extensionNet).then((v) {
                  getPlugins();
                  initPlugins();
                });
              },
              child: Text('网络安装'),
            ),
          ],
        ),
      ),
      content: CustomScrollView(
        slivers: [
          FluentGroup(
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
                    child: FluentListTile(
                      key: ValueKey(index),
                      leading: AppImage(url: "${item.icon}", width: 40, height: 40),
                      title: "${item.name} ${item.version}",
                      subtitle: "${item.desc}",
                      trailing: material.IconButton(
                        padding: EdgeInsets.zero,
                        icon: Padding(padding: EdgeInsets.all(8), child: material.Icon(material.Icons.clear)),
                        onPressed: () async {
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
                        context.push(Routes.extensionDetail, extra: item);
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
          SliverGap(16),
        ],
      ),
    );
  }

  Future<void> deleteExtension(String? package) async {
    await AppDB.remove(table: Constant.KEY_EXTENSION, queryCondition: where("package").equals(package));
  }
}
