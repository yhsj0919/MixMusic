import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_background_color.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';

class LoginByCookiePage extends StatefulWidget {
  const LoginByCookiePage({super.key});

  @override
  State<LoginByCookiePage> createState() => _LoginByCookiePageState();
}

class _LoginByCookiePageState extends State<LoginByCookiePage> {
  MusicApi? api;
  RxnString cookie = RxnString();
  var controller = TextEditingController(text: "");
  UserController userController = Get.put(UserController());
  PluginsInfo? plugin;
  ThemeController theme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    plugin = Get.arguments;

    api = ApiFactory.api(package: plugin?.package ?? "");
    getCookie();
  }

  void getCookie() async {
    cookie.value = (await api?.getCookie())?.data ?? "";
    controller.text = cookie.value ?? "";
  }

  @override
  Widget build(BuildContext context) {
    // 获取状态栏的高度
    double statusBarHeight = max(MediaQuery.of(context).padding.top, 16);
    double bottom = max(MediaQuery.of(context).padding.bottom, 16);
    return Scaffold(
      body: HyperBackgroundColor(
        color: theme.getColorByPackage(plugin?.package),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text("Cookie设置"),
            ),
            HyperGroup(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    maxLines: 16,
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "请输入cookie",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                  // height: 45,
                  margin: EdgeInsets.all(12),
                  child: FilledButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0), // 设置圆角
                          ),
                        ),
                        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20, vertical: 20)),
                      ),
                      onPressed: () {
                        print(controller.text);
                        api?.setCookie(cookie: controller.text);
                        userController.getAllUser().then((v) {
                          Get.back();
                        });
                      },
                      child: Text("保存"))),
            ),
            SliverGap(bottom)
          ],
        ),
      ),
    );
  }
}
