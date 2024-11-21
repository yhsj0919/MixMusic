import 'dart:io';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/app_theme.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_icon.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
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
          HyperAppbar(
            title: "设置",
          ),
          HyperGroup(
            children: [
              const HyperListTile(
                leading: HyperIcon(color: Colors.blue, icon: Icons.group),
                title: "插件化音乐播放器",
                subtitle: "加企鹅群催更:89220779",
              ),
              HyperListTile(
                  leading: HyperIcon(color: Colors.blue, icon: Icons.light_mode),
                  title: "主题",
                  subtitle: "切换日间夜间主题",
                  trailing: HyperTrailing(),
                  onTap: () {
                    if (Theme.of(context).brightness == Brightness.dark) {
                      Get.changeThemeMode(ThemeMode.light);
                    } else {
                      Get.changeThemeMode(ThemeMode.dark);
                    }
                  }),
            ],
          ),
          SliverToBoxAdapter(child: Container(height: 12)),
          HyperGroup(title: "插件", children: [
            HyperListTile(
                leading: HyperIcon(color: Colors.blue, icon: Icons.extension_rounded),
                title: "插件",
                subtitle: "安装插件，获取资源",
                trailing: HyperTrailing(),
                onTap: () {
                  Get.toNamed(Routes.extension);
                }),
            HyperListTile(
                leading: HyperIcon(color: Colors.blue, icon: Icons.track_changes_rounded),
                title: "音源匹配",
                subtitle: "在其他站点搜索同名歌曲",
                trailing: HyperTrailing(),
                onTap: () {
                  Get.toNamed(Routes.matchSite);
                }),
            HyperListTile(
                leading: HyperIcon(color: Colors.blue, icon: Icons.home_work_rounded),
                title: "首页展示",
                subtitle: "配置首页显示的数据",
                trailing: HyperTrailing(),
                onTap: () {
                  Get.toNamed(Routes.homeSite);
                }),
            HyperListTile(
                leading: HyperIcon(color: Colors.blue, icon: Icons.cookie),
                title: "站点登录",
                subtitle: "配置cookie，实现登录",
                trailing: HyperTrailing(),
                onTap: () {
                  Get.toNamed(Routes.cookieSetting);
                }),
          ]),
          SliverToBoxAdapter(child: Container(height: 12)),
          HyperGroup(title: "下载", children: [
            Obx(() => HyperListTile(
                leading: HyperIcon(color: Colors.blue, icon: Icons.folder_rounded),
                title: "下载目录",
                subtitle: downloadFolder.value ?? "暂无设置",
                trailing: HyperTrailing(),
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
          ]),
          SliverToBoxAdapter(child: Container(height: 12)),
          HyperGroup(title: "电源", children: [
            HyperListTile(
                leading: HyperIcon(color: Colors.blue, icon: Icons.battery_unknown_rounded),
                title: "电源策略",
                subtitle: "音乐通知显示异常使用",
                trailing: HyperTrailing(),
                onTap: () {
                  openBattery();
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
