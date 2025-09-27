import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/fluent_page.dart';

class DesktopAppPlayListPage extends StatelessWidget {
  DesktopAppPlayListPage({super.key, this.onTap});

  final GestureTapCallback? onTap;

  MusicController music = Get.put(MusicController());

  @override
  Widget build(BuildContext context) {
    return FluentScaffoldPage(
      padding: EdgeInsets.zero,
      header: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text("播放列表", style: FluentTheme.of(context).typography.bodyLarge),
            Obx(() => Text(" (${music.musicList.length})")),
            Expanded(child: Container()),
            IconButton(onPressed: () {}, icon: const Icon(FluentIcons.remove_from_shopping_list, size: 20)),
          ],
        ),
      ),
      content: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          slivers: [
            PinnedHeaderSliver(
              child: Container(height: 1, width: double.infinity, color: Colors.black.withAlpha((255 * 0.1).toInt())),
            ),
            Obx(
              () => SliverList.builder(
                itemCount: music.musicList.length,
                itemBuilder: (BuildContext context, int index) {
                  var song = music.musicList[index];
                  return Obx(
                    () => ListTile.selectable(
                      selected: music.currentMusic.value?.id.toString() == song.id.toString(),
                      leading: AppImage(url: song.pic ?? "", width: 40, height: 40),
                      title: Row(
                        children: [
                          Flexible(child: Text(song.title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis)),
                          song.vip == 1
                              ? Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                    border: Border.all(width: 1, color: Colors.green),
                                  ),
                                  child: Text("VIP", maxLines: 1, style: TextStyle(fontSize: 10, color: Colors.green)),
                                )
                              : Container(),
                        ],
                      ),
                      subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
                      onPressed: () {
                        music.play(music: song);
                        onTap?.call();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
