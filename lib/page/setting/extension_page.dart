import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/home/home_controller.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
import 'package:mix_music/widgets/plugin_item.dart';

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

  @override
  void initState() {
    super.initState();
    homeSite = Sp.getString(Constant.KEY_HOME_SITE);

    getPlugins();
  }

  void getPlugins() {
    List<PluginsInfo>? list = Sp.getList(Constant.KEY_EXTENSION);
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
              var result = await FilePicker.platform.pickFiles(
                dialogTitle: "选择插件",
                lockParentWindow: true,
                type: FileType.custom,
                allowedExtensions: ["js"],
              );
              if (result != null) {
                File file = File(result.files.single.path!);
                var baiduPlugins = parseExtension(file.readAsStringSync());
                if (baiduPlugins == null) {
                  print("插件无效");
                } else {
                  Sp.addList(Constant.KEY_EXTENSION, baiduPlugins, check: (oldValue, newValue) {
                    return oldValue.package == newValue.package;
                  }).then((v) {
                    initPlugins();
                  }).catchError((e) {
                    print("插件已经安装");
                  });
                }
              } else {
                // User canceled the picker
              }

              getPlugins();
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_link_outlined),
            label: '网络',
            onTap: () {
              // 第二个选项的点击事件
              print('网络导入');
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const HyperAppbar(title: "插件"),
          HyperGroup(
            title: "已安装",
            children: [
              ListView.builder(
                padding: EdgeInsets.all(0),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plugins.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  var item = plugins[index];
                  return HyperListTile(
                    leading: HyperLeading(
                      size: 40,
                      child: AppImage(url: "${item.icon}"),
                    ),
                    title: "${item.name} ${item.version}",
                    subtitle: "${item.desc}",
                    trailing: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: HyperTrailing(
                          icon: Icons.clear,
                        ),
                      ),
                      onTap: () async {
                        ///删除设置的首页
                        if (homeSite == item.package) {
                          Sp.remove(Constant.KEY_HOME_SITE);
                        }
                        await Sp.removeList<PluginsInfo>(Constant.KEY_EXTENSION, check: (old) {
                          return old.package == item.package;
                        });
                        getPlugins();
                        initPlugins();
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).push(OpacityRoute(builder: (context) => ExtensionDetailPage(pluginInfo: item)));
                    },
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
