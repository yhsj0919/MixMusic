import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/method_item.dart';

class ExtensionDetailPage extends StatefulWidget {
  const ExtensionDetailPage({super.key, required this.pluginInfo});

  final PluginsInfo pluginInfo;

  @override
  State<ExtensionDetailPage> createState() => _ExtensionDetailPageState();
}

class _ExtensionDetailPageState extends State<ExtensionDetailPage> {
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
    return Scaffold(
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   mixApi?.searchSong(keyword: "周杰伦", page: 0, size: 20).then((list) {
      //     list.data?.forEach((e) {
      //       print(e.title);
      //     });
      //   }).catchError((e) {
      //     print(e);
      //   });
      // }),
      body: CustomScrollView(
        slivers: [
          HyperAppbar(
            title: "${widget.pluginInfo.name}",
          ),
          HyperGroup(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppImage(url: "${widget.pluginInfo.icon}"),
                    const Gap(8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.work_outline_outlined, size: 18),
                            const Gap(4),
                            Text("${widget.pluginInfo.package}", style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.cloud_outlined, size: 18),
                            const Gap(4),
                            Text("${widget.pluginInfo.site}", style: Theme.of(context).textTheme.bodyLarge),
                            const Gap(4),
                            const Icon(Icons.person_outlined, size: 18),
                            const Gap(4),
                            Text("${widget.pluginInfo.author}", style: Theme.of(context).textTheme.bodyLarge),
                            const Gap(4),
                            const Icon(Icons.update, size: 18),
                            const Gap(4),
                            Text("${widget.pluginInfo.version}+${widget.pluginInfo.versionCode}", style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.public, size: 18),
                            const Gap(4),
                            Text("${widget.pluginInfo.webSite}", style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.bookmark_border_rounded, size: 18),
                            const Gap(4),
                            Text("${widget.pluginInfo.desc}", style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var type = modules.keys.elementAt(index);
                var value = modules[type];
                return MethodItem(
                  modules: type,
                  methods: value,
                  onChipTap: (key) {
                    mixApi?.invokeMethod(method: "music.$type.$key").then((value) {
                      print(json.encode(value));
                    }).catchError((e) {
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
