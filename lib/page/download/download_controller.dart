import 'dart:io';

import 'package:get/get.dart';
import 'package:mix_music/api/common_api.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:path_provider/path_provider.dart';

import '../../widgets/message.dart';

enum ButtonState { download, cancel, pause, resume, reset }

class DownloadController extends GetxController {
  RxList<MixDownload> tasks = RxList();
  var fileRoot = "";

  @override
  onInit() {
    super.onInit();
  }

  Future<void> initDir() async {
    if (Platform.isAndroid) {
      fileRoot = "storage/emulated/0/MixMusic/music";
    } else {
      fileRoot = "${(await getApplicationDocumentsDirectory()).path}/MixMusic/music";
    }
    Directory myFolder = Directory(fileRoot);
    if ((await myFolder.exists())) {
      Directory myFolder = Directory(fileRoot);

      myFolder.create(recursive: true).then((value) {}).catchError((e) {
        showError("文件创建失败：$e");
      });
    }
  }

  addTask(MixDownload download) async {
    initDir();

    if (tasks.where((v) => v.id.toString().hashCode == download.id.toString().hashCode).isEmpty) {
      tasks.add(download);
      CommonApi.download(download.url ?? "", fileRoot, download.title, onReceiveProgress: (int count, int total) {
        print('$total======>$count');
      }).then((v) {
        print(v);
        showComplete("${download.title}下载完成\n$v");
      });
    }
  }
}
