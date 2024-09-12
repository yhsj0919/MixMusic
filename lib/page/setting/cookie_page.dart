import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';

class CookiePage extends StatefulWidget {
  const CookiePage({super.key});

  @override
  State<CookiePage> createState() => _CookiePageState();
}

class _CookiePageState extends State<CookiePage> {
  RxList<PluginsInfo> plugins = RxList();

  @override
  void initState() {
    super.initState();

    getPlugins();
  }

  void getPlugins() {
    List<PluginsInfo>? list = Sp.getList(Constant.KEY_EXTENSION);
    plugins.clear();
    plugins.addAll(list ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text("Cookie设置"),
          ),
          SliverList.builder(
            itemCount: plugins.length,
            itemBuilder: (BuildContext context, int index) {
              var plugin = plugins[index];
              var cookie = Sp.getString("${Constant.KEY_COOKIE}_${plugin.package}");
              return CommonItem(
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: AppImage(url: "${plugin.icon}", width: 40, height: 40),
                  title: Text("${plugin.name}"),
                  subtitle: Text(cookie?.isNotEmpty == true ? "$cookie" : "未设置"),
                  onTap: () {
                    var controller = TextEditingController(text: cookie);

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('设置'),
                          content: TextField(
                            maxLines: 5,
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: "请输入cookie",
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('取消'),
                              onPressed: () {
                                Navigator.of(context).pop(); // 关闭对话框
                              },
                            ),
                            TextButton(
                              child: const Text('确定'),
                              onPressed: () {
                                print(controller.text);
                                Sp.setString("${Constant.KEY_COOKIE}_${plugin.package}", controller.text);
                                Navigator.of(context).pop(); // 关闭对话框
                              },
                            ),
                          ],
                        );
                      },
                    ).then((v) {
                      setState(() {});
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
