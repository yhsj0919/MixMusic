import 'dart:io';

import 'package:get/get.dart';
import 'package:mix_music/api/common_api.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/utils/sp.dart';

import '../../widgets/message.dart';

enum ButtonState { download, cancel, pause, resume, reset }

class DownloadController extends GetxController {
  RxList<MixDownload> tasks = RxList();
  String? fileRoot;

  @override
  onInit() {
    super.onInit();
  }

  Future<void> initDir() async {
    fileRoot = Sp.getString(Constant.KEY_DOWNLOAD_FOLDER);
    if (fileRoot != null) {
      Directory myFolder = Directory(fileRoot!);
      if ((await myFolder.exists())) {
        myFolder.create(recursive: true).then((value) {}).catchError((e) {
          showError("文件创建失败：$e");
        });
      }
    } else {
      showError("请先设置下载目录");
    }
  }

  addTask(MixDownload download) async {
    initDir();

    if (tasks.where((v) => v.id.toString().hashCode == download.id.toString().hashCode).isEmpty) {
      tasks.add(download);
      if (fileRoot != null) {
        CommonApi.download(download.url ?? "", fileRoot!, download.title, onReceiveProgress: (int count, int total) {
          print('$total======>$count');
        }).then((v) {
          print(v);
          showComplete("${download.title}下载完成\n$v");
        });
      }
    }
  }
}
