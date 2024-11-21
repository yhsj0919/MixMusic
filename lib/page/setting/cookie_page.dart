import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

class CookiePage extends StatefulWidget {
  const CookiePage({super.key});

  @override
  State<CookiePage> createState() => _CookiePageState();
}

class _CookiePageState extends State<CookiePage> {
  RxList<PluginsInfo> plugins = RxList();
  UserController userController = Get.put(UserController());

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
          HyperAppbar(
            title: "Cookie设置",
          ),
          HyperGroup(
            title: "需要登录的站点",
            children: [
              ListView.builder(
                padding: EdgeInsets.all(0),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: plugins.length,
                itemBuilder: (BuildContext context, int index) {
                  var plugin = plugins[index];
                  var api = ApiFactory.api(package: plugin.package ?? "");
                  var cookie = api?.getCookie();
                  var user = userController.userInfos[plugin.package ?? ""];

                  return ListTile(
                    leading: HyperLeading(
                      size: 40,
                      child: AppImage(url: "${plugin.icon}"),
                    ),
                    title: Text("${plugin.name}"),
                    subtitle: Text(
                      cookie?.isNotEmpty == true ? "${user?.name ?? "未知"} ${user?.login == 1 ? "已登录" : "未登录"} ${user?.vip == 1 ? "VIP" : "普通用户"}" : "未设置",
                      maxLines: 1,
                    ),
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
                                  api?.setCookie(cookie: controller.text);
                                  Navigator.of(context).pop(); // 关闭对话框
                                  userController.getAllUser().then((v) {
                                    setState(() {});
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ).then((v) {
                        setState(() {});
                      });
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
