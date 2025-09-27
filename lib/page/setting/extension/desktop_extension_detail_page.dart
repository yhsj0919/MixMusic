import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_method_item.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/method_item.dart';

class DesktopExtensionDetailPage extends StatefulWidget {
  const DesktopExtensionDetailPage({super.key, required this.pluginInfo});

  final PluginsInfo pluginInfo;

  @override
  State<DesktopExtensionDetailPage> createState() =>
      _DesktopExtensionDetailPageState();
}

class _DesktopExtensionDetailPageState
    extends State<DesktopExtensionDetailPage> {
  MusicApi? mixApi;

  var modules = <String, List<String>>{};

  @override
  void initState() {
    super.initState();
    mixApi = ApiFactory.api(package: widget.pluginInfo.package ?? "");

    getMethod();
  }

  void getMethod() {
    modules.clear();

    var value = mixApi?.keys(obj: "music") ?? [];
    for (var e in value) {
      var mm = mixApi?.keys(obj: "music.$e") ?? [];
      modules[e] = mm;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text("${widget.pluginInfo.name}"),
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
          FluentGroup(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppImage(url: "${widget.pluginInfo.icon}"),
                    const Gap(16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            const Icon(FluentIcons.mail, size: 16),
                            Text(
                              "${widget.pluginInfo.package}",
                              style: FluentTheme.of(context).typography.body,
                            ),
                            const Icon(FluentIcons.code, size: 18),
                            Text(
                              "${widget.pluginInfo.version}+${widget.pluginInfo.versionCode}",
                              style: FluentTheme.of(context).typography.body,
                            ),
                          ],
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            const Icon(FluentIcons.cloud, size: 18),
                            Text(
                              "${widget.pluginInfo.site}",
                              style: FluentTheme.of(context).typography.body,
                            ),
                            const Icon(FluentIcons.reminder_person, size: 18),
                            Text(
                              "${widget.pluginInfo.author}",
                              style: FluentTheme.of(context).typography.body,
                            ),

                            const Icon(FluentIcons.network_tower, size: 18),
                            Text(
                              "${widget.pluginInfo.webSite}",
                              style: FluentTheme.of(context).typography.body,
                            ),
                          ],
                        ),

                        Row(
                          spacing: 8,
                          children: [
                            const Icon(FluentIcons.note_forward, size: 18),
                            Text(
                              "${widget.pluginInfo.desc}",
                              style: FluentTheme.of(context).typography.body,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var type = modules.keys.elementAt(index);
                var value = modules[type];
                return FluentMethodItem(
                  modules: type,
                  methods: value,
                  onChipTap: (key) {
                    mixApi
                        ?.invokeMethod(method: "music.$type.$key")
                        .then((value) {
                          print(json.encode(value));
                        })
                        .catchError((e) {
                          print('出现异常》》》》》》$e');
                        });
                  },
                );
              },
              childCount: modules.length, // 列表项数量
            ),
          ),
        ],
      ),
    );
  }
}
