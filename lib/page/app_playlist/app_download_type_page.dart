import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/message.dart';

class AppDownloadTypePage extends StatelessWidget {
  AppDownloadTypePage({super.key, this.scrollController, this.onTap});

  final GestureTapCallback? onTap;

  ScrollController? scrollController;

  MusicController music = Get.put(MusicController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text("选择音质", style: Theme.of(context).textTheme.titleMedium),
              Expanded(child: Container()),
            ],
          ),
        ),
        Container(height: 1, width: double.infinity, color: Colors.black12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 0),
                shrinkWrap: true,
                controller: scrollController,
                itemCount: music.currentMusic.value?.quality?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  var item = music.currentMusic.value?.quality?[index];
                  return ListTile(
                    title: Text("${item?.title}"),
                    subtitle: Text("${((item?.size ?? 0) / 1024 / 1024).toStringAsFixed(2)}M"),
                    onTap: () {
                      showInfo("尚未实现该功能");
                      onTap?.call();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
