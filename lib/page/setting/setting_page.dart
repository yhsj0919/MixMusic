import 'dart:io';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/app_theme.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/setting_item.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  RxnString downloadFolder = RxnString(null);

  @override
  void initState() {
    super.initState();
    downloadFolder.value = Sp.getString(Constant.KEY_DOWNLOAD_FOLDER);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text("设置"),
          ),
          SliverList.list(children: [
            const SettingItem(
              icon: Icons.group,
              title: "插件管理安装插件",
              subtitle: "加企鹅群催更:89220779",
            ),
            SettingItem(
                icon: Icons.extension_rounded,
                title: "插件",
                subtitle: "安装插件，获取资源",
                onTap: () {
                  Get.toNamed(Routes.extension);
                }),
            Obx(() => SettingItem(
                icon: Icons.folder_rounded,
                title: "下载目录",
                subtitle: downloadFolder.value ?? "暂无设置",
                onTap: () async {
                  var result = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: "选择目录",
                    lockParentWindow: true,
                  );
                  if (result != null) {
                    downloadFolder.value = result;
                    Sp.setString(Constant.KEY_DOWNLOAD_FOLDER, result);
                  }
                })),
            SettingItem(
                icon: Icons.light_mode,
                title: "主题",
                subtitle: "切换日间夜间主题",
                onTap: () {
                  if (Theme.of(context).brightness == Brightness.dark) {
                    Get.changeThemeMode(ThemeMode.light);
                  } else {
                    Get.changeThemeMode(ThemeMode.dark);
                  }
                }),
            SettingItem(
                icon: Icons.battery_unknown_rounded,
                title: "电源策略",
                subtitle: "音乐通知显示异常使用",
                onTap: () {
                  openBattery();
                }),
            SettingItem(
                icon: Icons.track_changes_rounded,
                title: "音源匹配",
                subtitle: "在其他站点搜索同名歌曲",
                onTap: () {
                  Get.toNamed(Routes.matchSite);
                }),
            SettingItem(
                icon: Icons.home_work_rounded,
                title: "首页展示",
                subtitle: "配置首页显示的数据",
                onTap: () {
                  Get.toNamed(Routes.homeSite);
                }),
            SettingItem(
                icon: Icons.cookie,
                title: "站点登录",
                subtitle: "配置cookie，实现登录",
                onTap: () {
                  Get.toNamed(Routes.cookieSetting);
                }),
          ]),
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
