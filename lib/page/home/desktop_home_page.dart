import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/mv/desktop/desptop_mv_detail_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/HomeAlbumItem.dart';
import 'package:mix_music/widgets/fluent/HomeMvItem.dart';
import 'package:mix_music/widgets/fluent/HomePlayListItem.dart';
import 'package:mix_music/widgets/fluent/HomeSongItem.dart';
import 'package:mix_music/widgets/fluent/HomeTitleWidget.dart';

import 'home_controller.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  HomeController controller = Get.put(HomeController());
  final ScrollController scrollController = ScrollController();
  late EasyRefreshController refreshController;

  @override
  void initState() {
    super.initState();
    refreshController = EasyRefreshController(controlFinishLoad: false, controlFinishRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text("推荐"),
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
                  controller.getData();
                },
              ),
            ),
            Gap(8),
            SplitButton(
              enabled: true,
              flyout: FlyoutContent(
                constraints: BoxConstraints(maxWidth: 200.0),
                child: Wrap(
                  runSpacing: 10.0,
                  spacing: 8.0,
                  children: controller.plugins.map((item) {
                    return IconButton(
                      // autofocus: controller.homeSitePackage.value == item.package,
                      // style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(4.0))),
                      onPressed: () {
                        AppDB.setString(Constant.KEY_HOME_SITE, item.package ?? "");
                        controller.homeSitePackage.value = item.package;
                        controller.getData();
                        Navigator.of(context).pop(item);
                      },
                      icon: AppImage(url: item.icon ?? "", height: 32, width: 32),
                    );
                  }).toList(),
                ),
              ),
              child: Obx(
                () => Container(
                  padding: EdgeInsetsGeometry.all(4),
                  child: AppImage(url: controller.plugin.value?.icon ?? "", height: 26, width: 26),
                ),
              ),
            ),
          ],
        ),
      ),

      children: [
        HomeTitleWidget(
          title: Text('歌单'),
          onTapTitle: () {
            context.go(Routes.playList);
          },
        ),
        Gap(4),
        buildPlayList(),
        Gap(16),
        HomeTitleWidget(
          title: Text('专辑'),
          onTapTitle: () {
            context.go(Routes.album);
          },
        ),
        Gap(4),
        buildAlbum(),
        Gap(16),
        HomeTitleWidget(
          title: Text('MV'),
          onTapTitle: () {
            context.go(Routes.mv);
          },
        ),
        Gap(4),
        buildMv(),
        Gap(16),
        HomeTitleWidget(title: Text('新歌')),
        Gap(4),
        buildSong(),
        Gap(32),
      ],
    );
  }

  Widget buildPlayList() {
    return Container(
      height: 200,
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.playlist.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              var item = controller.playlist[index];
              return HomePlayListItem(
                item: item,
                onTap: () {
                  context.push(Routes.playListDetail, extra: item);
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 4),
          ),
        ),
      ),
    );
  }

  Widget buildAlbum() {
    return Container(
      height: 200,
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.albumList.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              var item = controller.albumList[index];
              return HomeAlbumItem(
                item: item,
                onTap: () {
                  context.push(Routes.albumDetail, extra: item);
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 4),
          ),
        ),
      ),
    );
  }

  Widget buildMv() {
    return Container(
      height: 200,
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.mvList.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              var item = controller.mvList[index];
              return HomeMvItem(
                item: item,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(FluentPageRoute(builder: (context) => DesktopMvDetailPage(item: item)));
                  // context.go(Routes.mvDetail, extra: item);
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 4),
          ),
        ),
      ),
    );
  }

  Widget buildSong() {
    return Container(
      height: 200,
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.songList.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              var item = controller.songList[index];
              return HomeSongItem(
                item: item,
                onTap: () {
                  controller.music.playList(
                    list: controller.songList,
                    index: index,
                  );
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 4),
          ),
        ),
      ),
    );
  }
}
