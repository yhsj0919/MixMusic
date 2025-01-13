import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/route/routes.dart';
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
    plugins.value = ApiFactory.getLoginPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          HyperAppbar(
            title: "站点登录",
          ),
          SliverToBoxAdapter(
            child: ListView.separated(
              padding: EdgeInsets.all(0),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: plugins.length,
              itemBuilder: (BuildContext context, int index) {
                var plugin = plugins[index];
                var user = userController.userInfos[plugin.package ?? ""];
                var detailMethod = ApiFactory.getLoginMethod(plugin.package ?? "") ?? [];

                return HyperGroup(
                  inSliver: false,
                  children: [
                    ListTile(
                      leading: HyperLeading(
                        size: 40,
                        child: AppImage(url: "${plugin.icon}"),
                      ),
                      title: Text("${plugin.name}"),
                      subtitle: Text(
                        user?.login == 1 ? "${user?.name ?? "未知"} ${user?.login == 1 ? "已登录" : "未登录"} ${user?.vip == 1 ? "VIP" : "普通用户"}" : "未登录",
                        maxLines: 1,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: detailMethod.map((element) {
                          print(element);
                          if (element == "cookie") {
                            return IconButton(
                                onPressed: () {
                                  Get.toNamed(Routes.loginByCookie, arguments: plugin)?.then((v) {
                                    setState(() {});
                                  });
                                },
                                icon: Icon(Icons.cookie));
                          }
                          if (element == "phone") {
                            return IconButton(
                                onPressed: () {
                                  Get.toNamed(Routes.loginByPhone, arguments: plugin)?.then((v) {
                                    setState(() {});
                                  });
                                },
                                icon: Icon(Icons.phone_android));
                          }
                          if (element == "user") {
                            return IconButton(onPressed: () {}, icon: Icon(Icons.person));
                          }
                          if (element == "web") {
                            return IconButton(onPressed: () {}, icon: Icon(Icons.browser_updated));
                          }
                          if (element == "qr") {
                            return IconButton(onPressed: () {}, icon: Icon(Icons.qr_code));
                          }

                          return IconButton(onPressed: () {}, icon: Icon(Icons.error));
                        }).toList(),
                      ),
                    )
                  ],
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Gap(12);
              },
            ),
          )
        ],
      ),
    );
  }
}
