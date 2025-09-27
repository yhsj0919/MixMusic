import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/fluent/Fluent_song_item.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';

import 'app_history_music_controller.dart';

class DesktopAppHistoryMusicList extends StatefulWidget {
  const DesktopAppHistoryMusicList({super.key});

  @override
  State<DesktopAppHistoryMusicList> createState() => _DesktopAppHistoryMusicListState();
}

class _DesktopAppHistoryMusicListState extends State<DesktopAppHistoryMusicList> {
  AppHistoryMusicController controller = Get.put(AppHistoryMusicController());
  MusicController music = Get.put(MusicController());

  @override
  void initState() {
    super.initState();
    controller.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text('最近播放'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                  width: 1, // 边框宽度
                ),
                borderRadius: BorderRadius.circular(5), // 圆角半径
              ),
              child: IconButton(
                icon: Icon(FluentIcons.refresh),
                onPressed: () {
                  controller.getHistory();
                },
              ),
            ),
            Gap(8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                  width: 1, // 边框宽度
                ),
                borderRadius: BorderRadius.circular(5), // 圆角半径
              ),
              child: IconButton(
                icon: Icon(FluentIcons.remove_from_shopping_list),
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (context) => ContentDialog(
                      title: const Text('提示'),
                      content: SingleChildScrollView(child: Text('确定清空列表？')),
                      actions: [
                        Button(
                          child: const Text('关闭'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        FilledButton(
                          child: const Text('确定'),
                          onPressed: () async {
                            await controller.cleanHistory();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      content: PageCustomScrollView(
        controller: controller.refreshController,
        onRefresh: () {
          return controller.getHistory();
        },

        slivers: [
          Obx(
            () => SliverList.builder(
              itemCount: controller.musicList.length,
              itemBuilder: (BuildContext context, int index) {
                var song = controller.musicList[index];
                return FluentSongItem(
                  onTap: () {
                    music.playList(list: controller.musicList, index: index);
                  },
                  song: song,
                  index: index,
                  showSite: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
