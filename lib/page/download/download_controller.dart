import 'dart:io';

import 'package:get/get.dart';
import 'package:mix_music/api/common_api.dart';
import 'package:mix_music/api/download_manager/download_status.dart';
import 'package:mix_music/api/download_manager/download_task.dart';
import 'package:mix_music/api/download_manager/downloader.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/utils/sp.dart';

import '../../widgets/message.dart';

class DownloadController extends GetxController {
  RxList<MixDownload> mixDownload = RxList();
  RxList<DownloadTask> tasks = RxList();
  RxList<DownloadTask> downloadTasks = RxList();
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
    if (mixDownloadContains(download)) {
      //未添加的
      mixDownload.add(download);

      addDownload(download.url ?? "");

      print('>>>>>>>>>第一次下载>>>>>>>>>>>>>>');
    } else {
      var old = getOldMixDownload(download);

      //已添加的
      var task = downloadManager.getDownload(old.url ?? "");

      if (task?.status.value == DownloadStatus.failed) {
        downloadManager.removeDownload(old.url ?? "");

        mixDownload.remove(old);
        mixDownload.add(download);

        print('>>>>>>>>>下载失败的替换掉>>>>>>>>>>>>>>');
      } else {
        print('>>>>>>>>>下载完成的不处理>>>>>>>>>>>>>>');
      }
    }
  }

  Future<void> addDownload(String url) async {
    if (downloadManager.getDownload(url) == null) {
      var task = await downloadManager.addDownload(url, fileRoot!);
      if (task != null) {
        tasks.insert(0, task);
      }
    }
  }

  Future<void> removeDownload(String url) async {
    var task = downloadManager.getDownload(url);

    if (task?.status.value == DownloadStatus.failed) {
      downloadManager.removeDownload(url);
      downloadTasks.remove(task);
    }
  }

  bool mixDownloadContains(MixDownload download) {
    return mixDownload.where((v) => v.id.toString().hashCode == download.id.toString().hashCode).isEmpty;
  }

  MixDownload getOldMixDownload(MixDownload download) {
    return mixDownload.where((v) => v.id.toString().hashCode == download.id.toString().hashCode).first;
  }

  MixDownload getMixDownloadByUrl(String url) {
    return mixDownload.where((v) => v.url == url).first;
  }
}
