import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/download/download_controller.dart';

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
          SliverList.builder(
            itemCount: controller.tasks.length,
            itemBuilder: (BuildContext context, int index) {
              var item = controller.tasks[index];
              return ListTile(
                title: Text("${item.title}"),
              );
            },
          ),
        ],
      ),
    );
  }
}
