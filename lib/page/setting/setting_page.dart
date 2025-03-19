import 'dart:io';
import 'dart:math';

import 'package:disable_battery_optimizations_latest/disable_battery_optimizations_latest.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_icon.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
import 'package:mix_music/widgets/message.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 获取状态栏的高度
    double statusBarHeight = max(MediaQuery.of(context).padding.top, 16);
    double bottom = max(MediaQuery.of(context).padding.bottom, 16);
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: HyperBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text("设置"),
            ),
            HyperGroup(
              children: [
                HyperListTile(
                    leading: HyperIcon(color: Colors.blue, icon: Icons.auto_awesome),
                    title: "关于",
                    subtitle: "插件化音乐播放器",
                    onTap: () {
                      Get.toNamed(Routes.about);
                    }),
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
            SliverGap(12),
            HyperGroup(title: Text("插件"), children: [
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
                  subtitle: "登录获取更多资源",
                  trailing: HyperTrailing(),
                  onTap: () {
                    Get.toNamed(Routes.loginListSetting);
                  }),
            ]),
            SliverGap(12),
            HyperGroup(title: Text("播放与下载"), children: [
              HyperListTile(
                  leading: HyperIcon(color: Colors.blue, icon: Icons.play_arrow_rounded),
                  title: "播放设置",
                  subtitle: "音质选择，缓存设置",
                  trailing: HyperTrailing(),
                  onTap: () {
                    Get.toNamed(Routes.playSetting);
                  }),
              HyperListTile(
                  leading: HyperIcon(color: Colors.blue, icon: Icons.folder_rounded),
                  title: "下载设置",
                  subtitle: "保存路径，命名方式",
                  trailing: HyperTrailing(),
                  onTap: () {
                    Get.toNamed(Routes.downloadSetting);
                  }),
            ]),
            SliverGap(12),
            HyperGroup(title: Text("电源"), children: [
              HyperListTile(
                  leading: HyperIcon(color: Colors.blue, icon: Icons.battery_unknown_rounded),
                  title: "电源策略",
                  subtitle: "音乐通知显示异常使用",
                  trailing: HyperTrailing(),
                  onTap: () {
                    openBattery();
                  }),
            ]),
            SliverGap(12),
            HyperGroup(title: Text("调试"), children: [
              HyperListTile(
                  leading: HyperIcon(color: Colors.blue, icon: Icons.bug_report_rounded),
                  title: "调试弹窗",
                  subtitle: "供调试使用，可以响应alert方法",
                  trailing: HyperTrailing(),
                  onTap: () {
                    var alert = Sp.getBool(Constant.KEY_APP_DEBUG_ALERT) ?? false;

                    Sp.setBool(Constant.KEY_APP_DEBUG_ALERT, !alert);

                    showInfo(alert ? "已关闭弹窗" : "已开启弹窗");
                  }),
            ]),
            SliverGap(bottom + 12),
          ],
        ),
      ),
    );
  }

  openBattery() async {
    if (Platform.isAndroid) {
      bool? isBatteryOptimizationDisabled = await DisableBatteryOptimizationLatest.isBatteryOptimizationDisabled;
      if (isBatteryOptimizationDisabled != true) {
        await DisableBatteryOptimizationLatest.showDisableBatteryOptimizationSettings();
      } else {
        showInfo('已关闭电池优化');
      }
    }
  }
}
