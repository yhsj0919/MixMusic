import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/setting/login/user_controller.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_icon.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:permission_handler/permission_handler.dart';

class DesktopPlaySettingPage extends StatefulWidget {
  const DesktopPlaySettingPage({super.key});

  @override
  State<DesktopPlaySettingPage> createState() => _DesktopPlaySettingPageState();
}

class _DesktopPlaySettingPageState extends State<DesktopPlaySettingPage> {
  RxInt playQuality = RxInt(0);
  RxBool playWithOtherApp = RxBool(false);

  @override
  void initState() {
    super.initState();
    playQuality.value = AppDB.getInt(Constant.KEY_PLAY_QUALITY) ?? 128;
    playWithOtherApp.value = AppDB.getBool(Constant.KEY_PLAY_WITH_OTHER_APP) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text('播放设置'),
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
          Obx(
            () => FluentGroup(
              title: Text("播放音质"),
              trailing: Text("无法播放时会选择最低音质"),
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                      width: 1, // 边框宽度
                    ),
                    borderRadius: BorderRadius.circular(5), // 圆角半径
                  ),
                  child: ListTile.selectable(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: EdgeInsets.zero,
                    title: Text("标准"),
                    subtitle: Text("2-5M/首，128kbps"),
                    selected: playQuality.value == 128,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_PLAY_QUALITY, 128);
                      playQuality.value = 128;
                    },
                  ),
                ),

                Container(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                      width: 1, // 边框宽度
                    ),
                    borderRadius: BorderRadius.circular(5), // 圆角半径
                  ),
                  child: ListTile.selectable(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: EdgeInsets.zero,
                    title: Text("极高(HQ)"),
                    subtitle: Text("5-10M/首，近CD品质，最高320kbps"),
                    selected: playQuality.value == 320,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_PLAY_QUALITY, 320);
                      playQuality.value = 320;
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                      width: 1, // 边框宽度
                    ),
                    borderRadius: BorderRadius.circular(5), // 圆角半径
                  ),
                  child: ListTile.selectable(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: EdgeInsets.zero,
                    title: Text("无损(SQ)"),
                    subtitle: Text("10-30M/首，无损音质，最高48kHz/16bit"),
                    selected: playQuality.value == 1000,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_PLAY_QUALITY, 1000);
                      playQuality.value = 1000;
                    },
                  ),
                ),

                Container(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                      width: 1, // 边框宽度
                    ),
                    borderRadius: BorderRadius.circular(5), // 圆角半径
                  ),
                  child: ListTile.selectable(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: EdgeInsets.zero,
                    title: Text("高解析(Hi-Res)"),
                    subtitle: Text("大于30M/首，更饱满清晰的音质，最高192kHz/24bit"),
                    selected: playQuality.value == 2000,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_PLAY_QUALITY, 2000);
                      playQuality.value = 2000;
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                      width: 1, // 边框宽度
                    ),
                    borderRadius: BorderRadius.circular(5), // 圆角半径
                  ),
                  child: ListTile.selectable(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: EdgeInsets.zero,
                    title: Text("母带"),
                    subtitle: Text("大于100M/首，超清母带，192kHz/24bit"),
                    selected: playQuality.value == 3000,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_PLAY_QUALITY, 3000);
                      playQuality.value = 3000;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
