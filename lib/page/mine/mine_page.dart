import 'dart:io';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/app_theme.dart';
import 'package:mix_music/widgets/message.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("我的")),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.group),
            title: Text("插件放在MixMusic/plugins"),
            subtitle: Text("加企鹅群催更:89220779"),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text("主题"),
            subtitle: const Text("切换日间夜间主题"),
            onTap: () {
              if (Theme.of(context).brightness == Brightness.dark) {
                Get.changeTheme(lightTheme);
              } else {
                Get.changeTheme(darkTheme);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text("插件"),
            subtitle: const Text("插件管理"),
            onTap: () {
              Get.toNamed(Routes.plugins);
            },
          ),
          ListTile(
            leading: const Icon(Icons.battery_unknown_rounded),
            title: const Text("电源策略"),
            subtitle: const Text("音乐通知显示异常使用"),
            onTap: () {
              openBattery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes_rounded),
            title: const Text("音源匹配"),
            subtitle: const Text("在其他站点搜索同名歌曲"),
            onTap: () {
              Get.toNamed(Routes.matchSite);
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_work_rounded),
            title: const Text("首页展示"),
            subtitle: const Text("配置首页显示的数据"),
            onTap: () {
              Get.toNamed(Routes.homeSite);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cookie),
            title: const Text("站点登录"),
            subtitle: const Text("配置cookie，实现登录"),
            onTap: () {
              Get.toNamed(Routes.cookieSetting);
            },
          ),
        ],
      ),
    );
  }

  openBattery() async {
    if (Platform.isAndroid) {
      bool? isBatteryOptimizationDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
      if (isBatteryOptimizationDisabled != true) {
        await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      } else {
        showInfo('已关闭电池优化');
      }
    }
  }
}
