import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/common_api.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_net_info.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
import 'package:mix_music/widgets/message.dart';

class ExtensionNetPage extends StatefulWidget {
  const ExtensionNetPage({super.key});

  @override
  State<ExtensionNetPage> createState() => _ExtensionNetPageState();
}

class _ExtensionNetPageState extends State<ExtensionNetPage> {
  RxList<PluginsNetInfo> plugins = RxList();
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: HyperBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              surfaceTintColor: Colors.transparent,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: const Text("网络导入"),
            ),
            PinnedHeaderSliver(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12.0), // 圆角半径
                  // boxShadow: [ // 添加阴影
                  //   BoxShadow(
                  //     color: Colors.black26,
                  //     blurRadius: 5.0,
                  //     offset: Offset(0, 4),
                  //   ),
                  // ],
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '请输入插件地址',
                    // 搜索图标
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // 圆角
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          // 搜索按钮
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            // 处理搜索操作
                            showInfo("过一阵子加个扫码，方便输入");
                          },
                        ),
                        IconButton(
                          // 搜索按钮
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            if (controller.text.isEmpty || !controller.text.startsWith("http")) {
                              showInfo("请先输入链接");
                              return;
                            }
                            if (controller.text.endsWith(".js")) {
                              installPlugin(controller.text);
                            } else {
                              getPluginList(controller.text);
                            }
                          },
                        )
                      ],
                    ),
                  ),
                  onSubmitted: (value) {
                    if (controller.text.isEmpty || !controller.text.startsWith("http")) {
                      showInfo("请先输入链接");
                    }
                    if (controller.text.endsWith(".js")) {
                      installPlugin(controller.text);
                    } else {
                      getPluginList(controller.text);
                    }
                  },
                ),
              ),
            ),
            HyperGroup(
              title: Text("插件"),
              children: [
                Obx(() => ListView.builder(
                      padding: EdgeInsets.all(0),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plugins.value.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        var item = plugins[index];
                        return HyperListTile(
                          title: "${item.name}",
                          subtitle: "${item.version}",
                          trailing: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: HyperTrailing(
                                icon: Icons.install_desktop,
                              ),
                            ),
                            onTap: () async {
                              installPlugin(item.url ?? "");
                            },
                          ),
                        );
                      },
                    )),
              ],
            ),
            SliverGap(bottom + 16)
          ],
        ),
      ),
    );
  }

  void getPluginList(String url) {
    CommonApi.get<List<PluginsNetInfo>>(url).then((v) {
      plugins.clear();
      plugins.addAll(v ?? []);
    }).catchError((e) {
      showError("链接无效:$e");
    });
  }

  void installPlugin(String url) {
    CommonApi.get<String>(url).then((v) {
      var plugins = parseExtension(v);
      if (plugins == null) {
        showError("插件无效");
      } else {
        Sp.replaceList(Constant.KEY_EXTENSION, plugins, check: (oldValue, newValue) {
          return oldValue.package == newValue.package;
        }).then((v) {
          showInfo("${plugins.name} 安装成功");
        });
      }
    });
  }
}
