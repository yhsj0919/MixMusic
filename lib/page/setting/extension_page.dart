import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/plugin_item.dart';

import 'extension_detail_page.dart';

class ExtensionPage extends StatefulWidget {
  const ExtensionPage({super.key});

  @override
  State<ExtensionPage> createState() => _ExtensionPageState();
}

class _ExtensionPageState extends State<ExtensionPage> {
  List<PluginsInfo> plugins = [];

  @override
  void initState() {
    super.initState();

    getPlugins();
  }

  void getPlugins() {
    List<PluginsInfo>? list = Sp.getList(Constant.KEY_EXTENSION);
    setState(() {
      plugins = list ?? [];
    });
  }

  void initPlugins() {

    ApiFactory.init();
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
          const SliverAppBar.large(
            title: Text("插件"),
          ),
          SliverList.builder(
            itemCount: plugins.length,
            itemBuilder: (BuildContext context, int index) {
              var item = plugins[index];
              return PluginItem(
                leading: AppImage(url: "${item.icon}"),
                title: "${item.name} ${item.version}",
                subtitle: "${item.desc}",
                trailing: IconButton(
                    onPressed: () async {
                      await Sp.removeList<PluginsInfo>(Constant.KEY_EXTENSION, check: (old) {
                        return old.package == item.package;
                      });
                      getPlugins();
                    },
                    icon: const Icon(Icons.clear)),
                onTap: () {
                  Navigator.of(context).push(OpacityRoute(builder: (context) => ExtensionDetailPage(pluginInfo: item)));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
