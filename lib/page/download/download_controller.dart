import 'dart:io';

import 'package:get/get.dart';
import 'package:mix_music/api/common_api.dart';
import 'package:mix_music/api/download_manager/download_task.dart';
import 'package:mix_music/api/download_manager/downloader.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/utils/sp.dart';

import '../../widgets/message.dart';

class DownloadController extends GetxController {
  RxList<MixDownload> mixDownload = RxList();
  RxList<DownloadTask> tasks = RxList();
  String? fileRoot;
  var downloadManager = DownloadManager();

  Future<bool> initDir() async {
    fileRoot = Sp.getString(Constant.KEY_DOWNLOAD_FOLDER);
    if (fileRoot != null) {
      Directory myFolder = Directory(fileRoot!);
      if ((await myFolder.exists())) {
        myFolder.create(recursive: true).then((value) {}).catchError((e) {
          showError("文件创建失败：$e");
        });
      }
      return true;
    } else {
      return false;
    }
  }

  addTask(MixDownload download) async {
    if (!(await initDir())) {
      showError("请先设置下载目录");
      return;
    }
    showInfo("已加入下载列表");
    if (mixDownload.where((v) => v.id.toString().hashCode == download.id.toString().hashCode).isEmpty) {
      mixDownload.add(download);
    }
    if (fileRoot != null) {
      // CommonApi.download(download.url ?? "", fileRoot!, download.title, onReceiveProgress: (int count, int total) {
      //   print('$total======>$count');
      // }).then((v) {
      //   print(v);
      //   showComplete("${download.title}下载完成\n$v");
      // });

      var task = await downloadManager.addDownload(download.url ?? "", fileRoot!);
      if (task != null) {
        tasks.add(task);
      }
    }
  }
}
