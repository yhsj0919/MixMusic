import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/download_manager/download_status.dart';
import 'package:mix_music/api/download_manager/download_task.dart';
import 'package:mix_music/page/download/download_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  DownloadController controller = Get.put(DownloadController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text("下载管理"),
          ),
          HyperGroup(
            title: "下载中",
            children: [
              Obx(() => ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.mixDownload.length,
                    itemBuilder: (BuildContext context, int index) {
                      var mixDownload = controller.mixDownload[index];
                      var task = controller.downloadManager.getDownload(mixDownload.url ?? "");

                      return ListItem(
                        onDownloadPlayPausedPressed: (url) async {
                          setState(() {
                            if (task != null && !task.status.value.isCompleted) {
                              switch (task.status.value) {
                                case DownloadStatus.downloading:
                                  controller.downloadManager.pauseDownload(url);
                                  break;
                                case DownloadStatus.paused:
                                  controller.downloadManager.resumeDownload(url);
                                  break;
                                case DownloadStatus.queued:
                                // TODO: Handle this case.
                                case DownloadStatus.completed:
                                // TODO: Handle this case.
                                case DownloadStatus.failed:
                                // TODO: Handle this case.
                                case DownloadStatus.canceled:
                                // TODO: Handle this case.
                              }
                            } else {
                              controller.downloadManager.addDownload(url, "${controller.fileRoot}");
                            }
                          });
                        },
                        onDelete: (url) {
                          try {
                            var fileName = "${task?.request.path}${Platform.pathSeparator}${task?.request.fileName}";
                            var file = File(fileName);
                            file.delete();
                          } catch (e) {
                            print('文件异常，可能不存在');
                          }

                          controller.downloadManager.removeDownload(url);
                          controller.mixDownload.remove(mixDownload);
                        },
                        downloadTask: task,
                        title: task?.request.fileName,
                        leading: HyperLeading(
                          size: 40,
                          child: AppImage(url: mixDownload.pic ?? ""),
                        ),
                      );
                    },
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final Function(String) onDownloadPlayPausedPressed;
  final Function(String) onDelete;
  DownloadTask? downloadTask;

  String? title;
  Widget? leading;

  ListItem({Key? key, required this.onDownloadPlayPausedPressed, required this.onDelete, this.downloadTask, this.title, this.leading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title ?? "N/A", overflow: TextOverflow.ellipsis),
      subtitle: downloadTask != null && !downloadTask!.status.value.isCompleted
          ? ValueListenableBuilder(
              valueListenable: downloadTask!.progress,
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: value != 1
                      ? LinearProgressIndicator(
                          value: value,
                          color: downloadTask!.status.value == DownloadStatus.paused ? Colors.grey : Colors.amber,
                        )
                      : Text("${downloadTask?.request.path}${Platform.pathSeparator}${downloadTask?.request.fileName}"),
                );
              })
          : Text("${downloadTask?.request.path}${Platform.pathSeparator}${downloadTask?.request.fileName}"),
      trailing: downloadTask != null
          ? ValueListenableBuilder(
              valueListenable: downloadTask!.status,
              builder: (context, value, child) {
                switch (downloadTask!.status.value) {
                  case DownloadStatus.downloading:
                    return IconButton(
                        onPressed: () {
                          onDownloadPlayPausedPressed(downloadTask?.request.url ?? "");
                        },
                        icon: const Icon(Icons.pause));
                  case DownloadStatus.paused:
                    return IconButton(
                        onPressed: () {
                          onDownloadPlayPausedPressed(downloadTask?.request.url ?? "");
                        },
                        icon: const Icon(Icons.play_arrow));
                  case DownloadStatus.completed:
                    return IconButton(
                        onPressed: () {
                          onDelete(downloadTask?.request.url ?? "");
                        },
                        icon: const Icon(Icons.delete));
                  case DownloadStatus.failed:
                  case DownloadStatus.canceled:
                    return IconButton(
                        onPressed: () {
                          onDownloadPlayPausedPressed(downloadTask?.request.url ?? "");
                        },
                        icon: const Icon(Icons.download));
                  case DownloadStatus.queued:
                    return IconButton(
                        onPressed: () {
                          // onDownloadPlayPausedPressed(url);
                        },
                        icon: const Icon(Icons.list));
                }
                return Text("$value", style: TextStyle(fontSize: 16));
              })
          : IconButton(
              onPressed: () {
                onDownloadPlayPausedPressed(downloadTask?.request.url ?? "");
              },
              icon: const Icon(Icons.download)),
    );
  }
}
