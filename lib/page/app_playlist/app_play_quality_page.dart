import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/entity/mix_quality.dart';
import 'package:mix_music/page/download/download_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/message.dart';

typedef PlayQualityCallback = void Function(MixQuality quality);

class AppPlayQualityPage extends StatelessWidget {
  AppPlayQualityPage({super.key, this.scrollController, this.onTap});

  final PlayQualityCallback? onTap;

  ScrollController? scrollController;

  MusicController music = Get.put(MusicController());
  DownloadController controller = Get.put(DownloadController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text("播放音质", style: Theme.of(context).textTheme.bodyLarge),
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
                    subtitle: Text("${item?.size}"),
                    onTap: onTap == null
                        ? null
                        : () {
                            onTap?.call(item!);
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
