import 'dart:async';
import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_download.dart';

enum ButtonState { download, cancel, pause, resume, reset }

class DownloadController extends GetxController {
  RxList<MixDownload> tasks = RxList();

  ButtonState buttonState = ButtonState.download;
  bool downloadWithError = false;
  TaskStatus? downloadTaskStatus;
  DownloadTask? backgroundDownloadTask;
  StreamController<TaskProgressUpdate> progressUpdateStream = StreamController();

  bool loadAndOpenInProgress = false;
  bool loadABunchInProgress = false;
  bool loadBackgroundInProgress = false;
  String? loadBackgroundResult;

  @override
  onInit() {
    super.onInit();
    FileDownloader().configure(globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 100)),
    ], androidConfig: [
      (Config.useCacheDir, Config.whenAble),
    ], iOSConfig: [
      (Config.localize, {'Cancel': 'StopIt'}),
    ]).then((result) => debugPrint('Configuration result = $result'));

    FileDownloader().configure(globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 100)),
    ], androidConfig: [
      (Config.useCacheDir, Config.whenAble),
    ], iOSConfig: [
      (Config.localize, {'Cancel': 'StopIt'}),
    ]).then((result) => debugPrint('Configuration result = $result'));

    // Registering a callback and configure notifications
    FileDownloader()
        .registerCallbacks(taskNotificationTapCallback: myNotificationTapCallback)
        .configureNotificationForGroup(FileDownloader.defaultGroup,
            // For the main download button
            // which uses 'enqueue' and a default group
            running: const TaskNotification('Download {filename}', 'File: {filename} - {progress} - speed {networkSpeed} and {timeRemaining} remaining'),
            complete: const TaskNotification('{displayName} download {filename}', 'Download complete'),
            error: const TaskNotification('Download {filename}', 'Download failed'),
            paused: const TaskNotification('Download {filename}', 'Paused with metadata {metadata}'),
            progressBar: true)
        .configureNotificationForGroup('bunch',
            running: const TaskNotification('{numFinished} out of {numTotal}', 'Progress = {progress}'),
            complete: const TaskNotification("Done!", "Loaded {numTotal} files"),
            error: const TaskNotification('Error', '{numFailed}/{numTotal} failed'),
            progressBar: false,
            groupNotificationId: 'notGroup')
        .configureNotification(complete: const TaskNotification('Download {filename}', 'Download complete'), tapOpensFile: true); // dog can also open directly from tap

    // Listen to updates and process
    FileDownloader().updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          if (update.task == backgroundDownloadTask) {
            buttonState =
                switch (update.status) { TaskStatus.running || TaskStatus.enqueued => ButtonState.pause, TaskStatus.paused => ButtonState.resume, _ => ButtonState.reset };

            downloadTaskStatus = update.status;
          }

        case TaskProgressUpdate():
          progressUpdateStream.add(update); // pass on to widget for indicator
      }
    });
  }

  /// Process the user tapping on a notification by printing a message
  void myNotificationTapCallback(Task task, NotificationType notificationType) {
    debugPrint('Tapped notification $notificationType for taskId ${task.taskId}');
  }

  addTask(MixDownload download) async {
    if (tasks.where((v) => v.id.toString().hashCode == download.id.toString().hashCode).isEmpty) {
      tasks.add(download);

      await FileDownloader().enqueue(DownloadTask(
        url: download.url ?? "",
        filename: "${download.title}",
        group: 'bunch',
        updates: Updates.statusAndProgress,
      ));
    }
  }
}
