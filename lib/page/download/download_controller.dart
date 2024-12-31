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

    var nameType = Sp.getInt(Constant.KEY_DOWNLOAD_NAME) ?? 0;

    String downloadName;
    if (nameType == 1) {
      downloadName = "${download.title}-${download.artist}";
    } else if (nameType == 2) {
      downloadName = "${download.artist}-${download.title}";
    } else {
      downloadName = "${download.title}";
    }

    if (mixDownloadContains(download)) {
      if (download.url?.isNotEmpty == true) {
        //未添加的
        mixDownload.insert(0, download);

        addDownload(download.url ?? "", fileName: downloadName);

        print('>>>>>>>>>第一次下载>>>>>>>>>>>>>>');
      } else {
        showError("地址不存在");
      }
    } else {
      var old = getOldMixDownload(download);

      //已添加的
      var task = downloadManager.getDownload(old.url ?? "");

      if (task?.status.value == DownloadStatus.failed) {
        downloadManager.removeDownload(old.url ?? "");

        mixDownload.remove(old);
        mixDownload.insert(0, download);
        addDownload(download.url ?? "", fileName: downloadName);

        print('>>>>>>>>>下载失败的替换掉>>>>>>>>>>>>>>');
      } else {
        print('>>>>>>>>>下载完成的不处理>>>>>>>>>>>>>>');
      }
    }
  }

  Future<void> addDownload(String url, {String? fileName}) async {
    if (downloadManager.getDownload(url) == null) {
      downloadManager.addDownload(url, fileRoot!, fileName: fileName);
    }
  }

  Future<void> removeDownload(String url) async {
    var task = downloadManager.getDownload(url);

    if (task?.status.value == DownloadStatus.failed) {
      downloadManager.removeDownload(url);
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
