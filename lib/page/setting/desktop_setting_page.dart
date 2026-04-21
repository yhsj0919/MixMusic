import 'dart:io';

import 'package:disable_battery_optimizations_latest/disable_battery_optimizations_latest.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_list_tile.dart';
import 'package:mix_music/widgets/message.dart';

class DesktopSettingPage extends StatefulWidget {
  const DesktopSettingPage({super.key});

  @override
  State<DesktopSettingPage> createState() => _DesktopSettingPageState();
}

class _DesktopSettingPageState extends State<DesktopSettingPage> {
  var theme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text("设置")),
      content: CustomScrollView(
        slivers: [
          FluentGroup(
            children: [
              FluentListTile(
                leading: Icon(FluentIcons.chat),
                title: "关于",
                subtitle: "插件化音乐播放器",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  context.push(Routes.about);
                },
              ),
              FluentListTile(
                leading: Icon(FluentIcons.light),
                title: "主题",
                subtitle: "切换日间夜间主题",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  if (FluentTheme.of(context).brightness == Brightness.dark) {
                    theme.themeMode.value = ThemeMode.light;
                  } else {
                    theme.themeMode.value = ThemeMode.dark;
                  }
                },
              ),
            ],
          ),
          SliverGap(12),
          FluentGroup(
            title: Text("插件"),
            children: [
              FluentListTile(
                leading: Icon(FluentIcons.repo),
                title: "插件",
                subtitle: "安装插件，获取资源",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  context.push(Routes.extension);
                },
              ),
              FluentListTile(
                leading: Icon(FluentIcons.cloud_flow),
                title: "音源匹配",
                subtitle: "在其他站点搜索同名歌曲",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  context.push(Routes.matchSite);
                },
              ),
              FluentListTile(
                leading: Icon(FluentIcons.home_group),
                title: "首页展示",
                subtitle: "配置首页显示的数据",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  context.push(Routes.homeSite);
                },
              ),
              FluentListTile(
                leading: Icon(FluentIcons.power_shell),
                title: "站点登录",
                subtitle: "登录获取更多资源",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  context.push(Routes.loginListSetting);
                },
              ),
            ],
          ),
          SliverGap(12),
          FluentGroup(
            title: Text("播放与下载"),
            children: [
              FluentListTile(
                leading: Icon(FluentIcons.play),
                title: "播放设置",
                subtitle: "音质选择，缓存设置",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  context.push(Routes.playSetting);
                },
              ),
              FluentListTile(
                leading: Icon(FluentIcons.cloud_download),
                title: "下载设置",
                subtitle: "保存路径，命名方式",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  context.push(Routes.downloadSetting);
                },
              ),
            ],
          ),

          SliverGap(12),
          FluentGroup(
            title: Text("调试"),
            children: [
              FluentListTile(
                leading: Icon(FluentIcons.bug),
                title: "调试弹窗",
                subtitle: "供调试使用，可以响应alert方法",
                trailing: Icon(FluentIcons.chevron_right),
                onTap: () {
                  var alert = AppDB.getBool(Constant.KEY_APP_DEBUG_ALERT) ?? false;

                  AppDB.setBool(Constant.KEY_APP_DEBUG_ALERT, !alert);

                  showInfo(alert ? "已关闭调试弹窗" : "已开启调试弹窗");
                },
              ),
            ],
          ),
          SliverGap(12),
        ],
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
