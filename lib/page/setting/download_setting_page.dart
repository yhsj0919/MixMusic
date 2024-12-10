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
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_icon.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';
import 'package:mix_music/widgets/hyper/hyper_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadSettingPage extends StatefulWidget {
  const DownloadSettingPage({super.key});

  @override
  State<DownloadSettingPage> createState() => _DownloadSettingPageState();
}

class _DownloadSettingPageState extends State<DownloadSettingPage> {
  RxnString downloadFolder = RxnString(null);
  RxInt downloadName = RxInt(0);
  Rx<bool> storageStatus = Rx(false);
  Rx<bool> manageStatus = Rx(false);

  @override
  void initState() {
    super.initState();
    downloadFolder.value = Sp.getString(Constant.KEY_DOWNLOAD_FOLDER);
    downloadName.value = Sp.getInt(Constant.KEY_DOWNLOAD_NAME) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          HyperAppbar(
            title: "下载设置",
          ),
          HyperGroup(
            title: "保存目录",
            children: [
              Obx(() => HyperListTile(
                  // leading: HyperIcon(color: Colors.blue, icon: Icons.folder_rounded),
                  title: "下载目录",
                  subtitle: downloadFolder.value ?? "暂无设置",
                  trailing: HyperTrailing(),
                  onTap: () async {
                    getSystemVersion().then((value) async {
                      if (value >= 30) {
                        var ss = await getManageExternalStoragePermission();
                        if (ss) {
                          var result = await FilePicker.platform.getDirectoryPath(
                            dialogTitle: "选择目录",
                            lockParentWindow: true,
                          );
                          if (result != null) {
                            downloadFolder.value = result;
                            Sp.setString(Constant.KEY_DOWNLOAD_FOLDER, result);
                          }
                        } else {
                          showError("未获取文件权限");
                        }
                      } else {
                        var ss = await getStoragePermission();
                        if (ss) {
                          var result = await FilePicker.platform.getDirectoryPath(
                            dialogTitle: "选择目录",
                            lockParentWindow: true,
                          );
                          if (result != null) {
                            downloadFolder.value = result;
                            Sp.setString(Constant.KEY_DOWNLOAD_FOLDER, result);
                          }
                        } else {
                          showError("未获取文件权限");
                        }
                      }
                    });
                  })),
            ],
          ),
          SliverGap(12),
          Obx(() => HyperGroup(
                title: "命名方式",
                children: [
                  RadioListTile<int?>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text("歌曲名"),
                    groupValue: downloadName.value,
                    value: 0,
                    onChanged: (int? value) {
                      Sp.setInt(Constant.KEY_DOWNLOAD_NAME, value ?? 0);
                      downloadName.value = value ?? 0;
                    },
                  ),
                  RadioListTile<int?>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text("歌曲名-歌手"),
                    groupValue: downloadName.value,
                    value: 1,
                    onChanged: (int? value) {
                      Sp.setInt(Constant.KEY_DOWNLOAD_NAME, value ?? 1);
                      downloadName.value = value ?? 1;
                    },
                  ),
                  RadioListTile<int?>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text("歌手-歌曲名"),
                    groupValue: downloadName.value,
                    value: 2,
                    onChanged: (int? value) {
                      Sp.setInt(Constant.KEY_DOWNLOAD_NAME, value ?? 2);
                      downloadName.value = value ?? 2;
                    },
                  )
                ],
              ))
        ],
      ),
    );
  }

  Future<bool> getStoragePermission() async {
    var ss = await Permission.storage
        .onDeniedCallback(() {
          showError("已拒绝");
        })
        .onGrantedCallback(() {})
        .onPermanentlyDeniedCallback(() {
          showError("已永久拒绝");
        })
        .onRestrictedCallback(() {
          showError("权限不可用");
        })
        .onLimitedCallback(() {
          showError("使用本应用时允许");
        })
        .onProvisionalCallback(() {
          showError("本次允许");
        })
        .request();

    if (ss == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> getManageExternalStoragePermission() async {
    var ss = await Permission.manageExternalStorage
        .onDeniedCallback(() {
          showError("已拒绝");
        })
        .onGrantedCallback(() {})
        .onPermanentlyDeniedCallback(() {
          showError("已永久拒绝");
        })
        .onRestrictedCallback(() {
          showError("权限不可用");
        })
        .onLimitedCallback(() {
          showError("使用本应用时允许");
        })
        .onProvisionalCallback(() {
          showError("本次允许");
        })
        .request();

    if (ss == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  }

  Future<int> getSystemVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      return androidInfo.version.sdkInt;
    } else {
      return 29;
    }
  }
}
