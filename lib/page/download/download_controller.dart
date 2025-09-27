import 'dart:io';

import 'package:get/get.dart';
import 'package:mix_music/common/api/common_api.dart';
import 'package:mix_music/common/api/download_manager/download_status.dart';
import 'package:mix_music/common/api/download_manager/download_task.dart';
import 'package:mix_music/common/api/download_manager/downloader.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/common/entity/mix_download.dart';
import 'package:mix_music/utils/db.dart';

import '../../widgets/message.dart';

class DownloadController extends GetxController {
  RxList<MixDownload> mixDownload = RxList();
  RxList<MixDownload> oldDownload = RxList();
  String? fileRoot;
  var downloadManager = DownloadManager(maxConcurrentTasks: 1);

  @override
  void onInit() {
    super.onInit();

    // mixDownload.addAll(AppDB.getList<MixDownload>(Constant.KEY_APP_DOWNLOAD_LIST) ?? []);
    // mixDownload.forEach((a) {
    //   addTask(a);
    // });
  }

  Future<bool> initDir() async {
    fileRoot = AppDB.getString(Constant.KEY_DOWNLOAD_FOLDER);
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

    var nameType = AppDB.getInt(Constant.KEY_DOWNLOAD_NAME) ?? 0;

    String downloadName;
    if (nameType == 1) {
      downloadName = "${download.title} - ${download.artist}";
    } else if (nameType == 2) {
      downloadName = "${download.artist} - ${download.title}";
    } else {
      downloadName = "${download.title}";
    }
    downloadName = downloadName
        .replaceAll(":", "：")
        .replaceAll("\\", " ")
        .replaceAll("/", " ")
        .replaceAll("*", " ")
        .replaceAll("?", " ")
        .replaceAll("\"", "”")
        .replaceAll("<", "《")
        .replaceAll(">", "》")
        .replaceAll("|", " ");

    if (mixDownloadContains(download)) {
      if (download.url?.isNotEmpty == true) {
        //未添加的
        mixDownload.insert(0, download);
        // AppDB.insertList(Constant.KEY_APP_DOWNLOAD_LIST, download, index: 0, check: (oldValue, newValue) {
        //   return oldValue.package == newValue.package && oldValue.id.toString() == newValue.id.toString();
        // });

        var task = await addDownload(download.url ?? "", fileName: downloadName);
        task?.status.addListener(() {
          statusChange(task);
        });

        print('>>>>>>>>>第一次下载>>>>>>>>>>>>>>');
      } else {
        showError("地址不存在");
      }
    } else {
      var old = getOldMixDownload(download);

      //已添加的
      var task = downloadManager.getDownload(old.url ?? "");

      print(task?.request.path);

      if (task?.status.value == DownloadStatus.failed || task == null) {
        downloadManager.removeDownload(old.url ?? "");

        mixDownload.remove(old);
        mixDownload.insert(0, download);
        // AppDB.insertList(Constant.KEY_APP_DOWNLOAD_LIST, download, index: 0, check: (oldValue, newValue) {
        //   return oldValue.package == newValue.package && oldValue.id.toString() == newValue.id.toString();
        // });

        var task2 = await addDownload(download.url ?? "", fileName: downloadName);
        task2?.status.addListener(() {
          statusChange(task2);
        });

        print('>>>>>>>>>下载失败的替换掉>>>>>>>>>>>>>>');
      } else {
        print('>>>>>>>>>下载完成的不处理>>>>>>>>>>>>>>');
      }
    }
  }

  void statusChange(DownloadTask? task) {
    print("下载完成:${task?.request.fileName} ${task?.request} ${task?.status.value.name} ${task?.request.url}");
  }

  Future<DownloadTask?> addDownload(String url, {String? fileName}) async {
    if (downloadManager.getDownload(url) == null) {
      return downloadManager.addDownload(url, fileRoot!, fileName: fileName);
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
