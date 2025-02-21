import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/common_item.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_icon.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:permission_handler/permission_handler.dart';

class PlaySettingPage extends StatefulWidget {
  const PlaySettingPage({super.key});

  @override
  State<PlaySettingPage> createState() => _PlaySettingPageState();
}

class _PlaySettingPageState extends State<PlaySettingPage> {
  RxInt playQuality = RxInt(0);
  RxBool playWithOtherApp = RxBool(false);

  @override
  void initState() {
    super.initState();
    playQuality.value = Sp.getInt(Constant.KEY_PLAY_QUALITY) ?? 128;
    playWithOtherApp.value = Sp.getBool(Constant.KEY_PLAY_WITH_OTHER_APP) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HyperBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text("播放设置"),
            ),
            HyperGroup(
              children: [
                Obx(
                  () => SwitchListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text("允许与其他应用同时播放"),
                    subtitle: const Text("其他应用播放时不暂停"),
                    value: playWithOtherApp.value,
                    onChanged: (value) {
                      playWithOtherApp.value = value;
                      Sp.setBool(Constant.KEY_PLAY_WITH_OTHER_APP, value);

                      ApiFactory.initMatch();
                    },
                  ),
                )
              ],
            ),
            SliverGap(12),
            Obx(() => HyperGroup(
                  title: Text("播放音质"),
                  trailing: Text("无法播放时会选择最低音质"),
                  children: [
                    RadioListTile<int?>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text("标准"),
                      subtitle: Text("2-5M/首，128kbps"),
                      groupValue: playQuality.value,
                      value: 128,
                      onChanged: (int? value) {
                        Sp.setInt(Constant.KEY_PLAY_QUALITY, value ?? 128);
                        playQuality.value = value ?? 128;
                      },
                    ),
                    RadioListTile<int?>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text("极高(HQ)"),
                      subtitle: Text("5-10M/首，近CD品质，最高320kbps"),
                      groupValue: playQuality.value,
                      value: 320,
                      onChanged: (int? value) {
                        Sp.setInt(Constant.KEY_PLAY_QUALITY, value ?? 320);
                        playQuality.value = value ?? 320;
                      },
                    ),
                    RadioListTile<int?>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text("无损(SQ)"),
                      subtitle: Text("10-30M/首，无损音质，最高48kHz/16bit"),
                      groupValue: playQuality.value,
                      value: 1000,
                      onChanged: (int? value) {
                        Sp.setInt(Constant.KEY_PLAY_QUALITY, value ?? 1000);
                        playQuality.value = value ?? 1000;
                      },
                    ),
                    RadioListTile<int?>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text("高解析(Hi-Res)"),
                      subtitle: Text("大于30M/首，更饱满清晰的音质，最高192kHz/24bit"),
                      groupValue: playQuality.value,
                      value: 2000,
                      onChanged: (int? value) {
                        Sp.setInt(Constant.KEY_PLAY_QUALITY, value ?? 2000);
                        playQuality.value = value ?? 2000;
                      },
                    ),
                    RadioListTile<int?>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text("母带"),
                      subtitle: Text("大于100M/首，更饱满清晰的音质，最高192kHz/24bit"),
                      groupValue: playQuality.value,
                      value: 4000,
                      onChanged: (int? value) {
                        Sp.setInt(Constant.KEY_PLAY_QUALITY, value ?? 4000);
                        playQuality.value = value ?? 4000;
                      },
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
