import 'dart:ffi';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:mix_music/page/home/home_page.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../route/routes.dart';
import '../api_controller.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  ApiController api = Get.put(ApiController());

  Rx<bool> storageStatus = Rx(false);
  Rx<bool> manageStatus = Rx(false);
  Rx<bool> dirExists = Rx(false);
  var pluginRoot = "";

  @override
  void initState() {
    super.initState();

    getSystemVersion().then((value) {
      if (value < 33) {
        getStoragePermission();
      } else {
        storageStatus.value = true;
      }
      if (value > 30) {
        getManageExternalStoragePermission();
      } else {
        manageStatus.value = true;
      }
    });

    initDir();
  }

  Future<int> getSystemVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      return androidInfo.version.sdkInt;
    } else {
      return 32;
    }
  }

  Future<void> initDir() async {
    if (Platform.isAndroid) {
      pluginRoot = "storage/emulated/0/MixMusic/plugins";
    } else {
      pluginRoot = "${(await getApplicationDocumentsDirectory()).path} /MixMusic/plugins";
    }
    Directory myFolder = Directory(pluginRoot);
    if (!(await myFolder.exists())) {
      dirExists.value = false;
    } else {
      dirExists.value = true;
    }
  }

  Future<void> getStoragePermission() async {
    if ((await Permission.storage.status) == PermissionStatus.granted) {
      storageStatus.value = true;
    } else {
      storageStatus.value = false;
    }
  }

  Future<void> getManageExternalStoragePermission() async {
    if ((await Permission.manageExternalStorage.status) == PermissionStatus.granted) {
      manageStatus.value = true;
    } else {
      manageStatus.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("权限")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("该应用需要以下权限才能运行"),
            const SizedBox(height: 16),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("外部存储权限"),
                    const SizedBox(width: 16),
                    storageStatus.value
                        ? const Text("已授权")
                        : TextButton(
                            child: const Text("去授权"),
                            onPressed: () async {
                              await Permission.storage.onDeniedCallback(() {
                                storageStatus.value = false;
                                showError("已拒绝");
                              }).onGrantedCallback(() {
                                storageStatus.value = true;
                              }).onPermanentlyDeniedCallback(() {
                                storageStatus.value = false;
                                showError("已永久拒绝");
                              }).onRestrictedCallback(() {
                                storageStatus.value = false;
                                showError("权限不可用");
                              }).onLimitedCallback(() {
                                storageStatus.value = true;
                                showError("使用本应用时允许");
                              }).onProvisionalCallback(() {
                                storageStatus.value = true;
                                showError("本次允许");
                              }).request();
                            },
                          ),
                  ],
                )),
            const SizedBox(height: 16),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("管理外部存储权限"),
                    const SizedBox(width: 16),
                    manageStatus.value
                        ? const Text("已授权")
                        : TextButton(
                            child: const Text("去授权"),
                            onPressed: () async {
                              await Permission.manageExternalStorage.onDeniedCallback(() {
                                manageStatus.value = false;
                                showError("已拒绝");
                              }).onGrantedCallback(() {
                                manageStatus.value = true;
                              }).onPermanentlyDeniedCallback(() {
                                manageStatus.value = false;
                                showError("已永久拒绝");
                              }).onRestrictedCallback(() {
                                manageStatus.value = false;
                                showError("权限不可用");
                              }).onLimitedCallback(() {
                                manageStatus.value = true;
                                showError("使用本应用时允许");
                              }).onProvisionalCallback(() {
                                manageStatus.value = true;
                                showError("本次允许");
                              }).request();
                            },
                          ),
                  ],
                )),
            const SizedBox(height: 16),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("MixMusic/plugins目录"),
                    const SizedBox(width: 16),
                    dirExists.value
                        ? const Text("已创建")
                        : TextButton(
                            child: const Text("去创建"),
                            onPressed: () async {
                              Directory myFolder = Directory(pluginRoot);

                              myFolder.create(recursive: true).then((value) {
                                dirExists.value = value.existsSync();
                              }).catchError((e) {
                                showError("文件创建失败：$e");
                              });
                            },
                          ),
                  ],
                )),
            const SizedBox(height: 32),
            Obx(() => ElevatedButton(
                onPressed: storageStatus.value && manageStatus.value && dirExists.value
                    ? () async {
                        await api.initPlugins();
                        await Sp.setBool(Sp.KEY_FIRST_IN, false);
                        Get.offAndToNamed(Routes.main);
                      }
                    : null,
                child: const Text("去首页")))
          ],
        ),
      ),
    );
  }
}
