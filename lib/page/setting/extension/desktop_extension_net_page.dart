import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/common_api.dart';
import 'package:mix_music/common/entity/plugins_net_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:tiny_db/tiny_db.dart';

class DesktopExtensionNetPage extends StatefulWidget {
  const DesktopExtensionNetPage({super.key});

  @override
  State<DesktopExtensionNetPage> createState() => _DesktopExtensionNetPageState();
}

class _DesktopExtensionNetPageState extends State<DesktopExtensionNetPage> {
  RxList<PluginsNetInfo> plugins = RxList();
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).padding.bottom;

    return ScaffoldPage(
      header: PageHeader(
        title: Text("网络导入"),
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
      content: CustomScrollView(
        slivers: [
          PinnedHeaderSliver(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: TextBox(
                controller: controller,
                placeholder: '请输入插件地址',
                suffix: IconButton(
                  // 搜索按钮
                  icon: const Icon(FluentIcons.search),
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
          FluentGroup(
            title: Text("插件"),
            children: [
              Obx(
                () => ListView.builder(
                  padding: EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plugins.value.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    var item = plugins[index];
                    return FluentListTile(
                      title: "${item.name}",
                      subtitle: "${item.version}",
                      trailing: material.IconButton(
                        padding: EdgeInsets.zero,
                        icon: Padding(padding: EdgeInsets.all(8), child: Icon(material.Icons.install_desktop)),
                        onPressed: () async {
                          installPlugin(item.url ?? "");
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SliverGap(bottom + 16),
        ],
      ),
    );
  }

  void getPluginList(String url) {
    CommonApi.get<List<PluginsNetInfo>>(url)
        .then((v) {
          plugins.clear();
          plugins.addAll(v ?? []);
        })
        .catchError((e) {
          showError("链接无效:$e");
        });
  }

  void installPlugin(String url) {
    CommonApi.get<String>(url).then((v) {
      var plugins = parseExtension(v);
      if (plugins == null) {
        showError("插件无效");
      } else {
        AppDB.insertOrUpdate(table: Constant.KEY_EXTENSION, doc: JsonMapper.toMap(plugins)!, queryCondition: where("package").equals(plugins.name)).then((v) {
          showInfo("${plugins.name} 安装成功");
        });
      }
    });
  }
}
