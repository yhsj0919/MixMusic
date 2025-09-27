import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/setting/login/user_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

class DesktopLoginListPage extends StatefulWidget {
  const DesktopLoginListPage({super.key});

  @override
  State<DesktopLoginListPage> createState() => _DesktopLoginListPageState();
}

class _DesktopLoginListPageState extends State<DesktopLoginListPage> {
  RxList<PluginsInfo> plugins = RxList();
  UserController userController = Get.put(UserController());

  @override
  void initState() {
    super.initState();

    getPlugins();
    userController.userInfos.stream.listen((a) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void getPlugins() {
    plugins.value = ApiFactory.getLoginPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text("站点登录"),
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
            title: Text("下列插件可以登录"),
            children: [
              Obx(
                () => ListView.separated(
                  padding: EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: plugins.length,
                  itemBuilder: (BuildContext context, int index) {
                    var plugin = plugins[index];
                    var user = userController.userInfos[plugin.package ?? ""];
                    var detailMethod = ApiFactory.getLoginMethod(plugin.package ?? "") ?? [];

                    return FluentListTile(
                      leading: AppImage(url: "${plugin.icon}", width: 30, height: 30),
                      title: "${plugin.name}",
                      subtitle: user?.login == 1 ? "${user?.name ?? "未知"} ${user?.login == 1 ? "已登录" : "未登录"} ${user?.vip == 1 ? "VIP" : "普通用户"} ${user?.vipEndTime}" : "未登录",
                      trailing: Row(
                        spacing: 8,
                        children: [
                          ...detailMethod.map((element) {
                            if (element == "cookie") {
                              return IconButton(
                                onPressed: () {
                                  context.push(Routes.loginByCookie, extra: plugin).then((v) {
                                    setState(() {});
                                  });
                                },
                                icon: Icon(FluentIcons.cake, size: 20),
                              );
                            }
                            if (element == "phone") {
                              return IconButton(
                                onPressed: () {
                                  context.push(Routes.loginByPhone, extra: plugin).then((v) {
                                    setState(() {});
                                  });
                                },
                                icon: Icon(FluentIcons.phone, size: 20),
                              );
                            }
                            if (element == "user") {
                              return IconButton(onPressed: () {}, icon: Icon(FluentIcons.user_followed));
                            }
                            if (element == "web") {
                              return IconButton(
                                onPressed: () {
                                  context.push(Routes.loginByWeb, extra: plugin).then((v) {
                                    setState(() {});
                                  });
                                },
                                icon: Icon(FluentIcons.my_network, size: 20),
                              );
                            }
                            if (element == "qr") {
                              return IconButton(onPressed: () {}, icon: Icon(FluentIcons.q_r_code, size: 20));
                            }

                            return IconButton(onPressed: () {}, icon: Icon(FluentIcons.error, size: 20));
                          }).toList(),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Gap(2);
                  },
                ),
              ),
            ],
          ),

          SliverGap(16),
        ],
      ),
    );
  }
}
