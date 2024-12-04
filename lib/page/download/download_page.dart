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
            title: Text("下载"),
          ),
          HyperGroup(
            title: "下载中",
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: controller.tasks.length,
                itemBuilder: (BuildContext context, int index) {
                  var url = controller.tasks[index].request.url;
                  return ListItem(
                      onDownloadPlayPausedPressed: (url) async {
                        setState(() {
                          var task = controller.downloadManager.getDownload(url);

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
                            controller.downloadManager.addDownload(url,
                                "${controller.fileRoot}/${controller.downloadManager.getFileNameFromUrl(url)}");
                          }
                        });
                      },
                      onDelete: (url) {
                        var fileName =
                            "${controller.fileRoot}/${controller.downloadManager.getFileNameFromUrl(url)}";
                        var file = File(fileName);
                        file.delete();

                        controller.downloadManager.removeDownload(url);
                        setState(() {});
                      },
                      url: url,
                      downloadTask: controller.downloadManager.getDownload(url));
                },
              ),
            ],
          ),
          SliverGap(12),
          HyperGroup(
            title: "已下载",
            children: [
              // ListView.builder(
              //   shrinkWrap: true,
              //   itemCount: controller.tasks.length,
              //   itemBuilder: (BuildContext context, int index) {
              //     var item = controller.tasks[index];
              //     return ListTile(
              //       title: Text("${item.title}"),
              //     );
              //   },
              // ),
            ],
          )
        ],
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final Function(String) onDownloadPlayPausedPressed;
  final Function(String) onDelete;
  DownloadTask? downloadTask;
  String url = "";

  ListItem({Key? key, required this.url, required this.onDownloadPlayPausedPressed, required this.onDelete, this.downloadTask}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.amber,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20))),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      url,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (downloadTask != null)
                      ValueListenableBuilder(
                          valueListenable: downloadTask!.status,
                          builder: (context, value, child) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text("$value", style: TextStyle(fontSize: 16)),
                            );
                          }),
                  ],
                )),
                downloadTask != null
                    ? ValueListenableBuilder(
                        valueListenable: downloadTask!.status,
                        builder: (context, value, child) {
                          switch (downloadTask!.status.value) {
                            case DownloadStatus.downloading:
                              return IconButton(
                                  onPressed: () {
                                    onDownloadPlayPausedPressed(url);
                                  },
                                  icon: const Icon(Icons.pause));
                            case DownloadStatus.paused:
                              return IconButton(
                                  onPressed: () {
                                    onDownloadPlayPausedPressed(url);
                                  },
                                  icon: const Icon(Icons.play_arrow));
                            case DownloadStatus.completed:
                              return IconButton(
                                  onPressed: () {
                                    onDelete(url);
                                  },
                                  icon: const Icon(Icons.delete));
                            case DownloadStatus.failed:
                            case DownloadStatus.canceled:
                              return IconButton(
                                  onPressed: () {
                                    onDownloadPlayPausedPressed(url);
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
                          onDownloadPlayPausedPressed(url);
                        },
                        icon: const Icon(Icons.download))
              ],
            ), // if (widget.item.isDownloadingOrPaused)
            if (downloadTask != null && !downloadTask!.status.value.isCompleted)
              ValueListenableBuilder(
                  valueListenable: downloadTask!.progress,
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: LinearProgressIndicator(
                        value: value,
                        color: downloadTask!.status.value == DownloadStatus.paused ? Colors.grey : Colors.amber,
                      ),
                    );
                  }),
            if (downloadTask != null)
              FutureBuilder<DownloadStatus>(
                  future: downloadTask!.whenDownloadComplete(),
                  builder: (BuildContext context, AsyncSnapshot<DownloadStatus> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return Text('I will wait till this download has been completed');
                      default:
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Text('Result: ${snapshot.data}');
                        }
                    }
                  })
          ],
        ),
      ),
    );
  }
}
