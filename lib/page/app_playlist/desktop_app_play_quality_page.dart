import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_download.dart';
import 'package:mix_music/common/entity/mix_quality.dart';
import 'package:mix_music/page/download/download_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/message.dart';

typedef PlayQualityCallback = void Function(MixQuality quality);

class DesktopAppPlayQualityPage extends StatelessWidget {
  DesktopAppPlayQualityPage({super.key, this.onTap});

  final PlayQualityCallback? onTap;

  MusicController music = Get.put(MusicController());
  DownloadController controller = Get.put(DownloadController());

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text("音质选择", style: FluentTheme.of(context).typography.bodyLarge),
        ),
        Container(height: 1, width: double.infinity, color: Colors.black.withAlpha((255 * 0.1).toInt())),

        Obx(
          () => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 0),
            shrinkWrap: true,
            itemCount: music.currentMusic.value?.quality?.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              var item = music.currentMusic.value?.quality?[index];
              return ListTile(
                title: Text("${item?.title}"),
                subtitle: Text("${item?.size}"),
                onPressed: onTap == null
                    ? null
                    : () {
                        onTap?.call(item!);
                      },
              );
            },
          ),
        ),
      ],
    );
  }
}
