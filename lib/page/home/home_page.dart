import 'dart:async';
import 'dart:math';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/widgets/hidable/hidable_widget.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/new_surface_theme.dart';
import 'package:mix_music/theme/surface_color_enum.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_card.dart';
import 'package:mix_music/widgets/hyper/hyper_group_big_title.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';
import 'package:mix_music/widgets/hyper/hyper_scaffold.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';

import '../app_playing/phone_playing.dart';
import '../app_playing/play_bar.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    // 获取状态栏的高度
    double statusBarHeight = max(MediaQuery.of(context).padding.top, 16);
    double bottom = max(MediaQuery.of(context).padding.bottom, 16);
    return HyperBackground(
        child: SafeArea(
            child: HyperScaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Hidable(
        controller: scrollController,
        enableOpacityAnimation: true, // optional, defaults to `true`.
        child: Container(
          alignment: Alignment.bottomRight,
          child: PlayBar(),
        ),
      ),
      center: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false, overscroll: false),
          child: PageCustomScrollView(
            controller: refreshController,
            scrollController: scrollController,
            onRefresh: () {
              controller.getData();
              return Future.delayed(Duration(milliseconds: 500)).then((v) {
                refreshController.finishRefresh(IndicatorResult.success, true);
              });
            },
            slivers: [
              context.isPhone
                  ? SliverGap(kToolbarHeight)
                  : PinnedHeaderSliver(
                      child: Container(
                        height: kToolbarHeight,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
              context.isPhone ? SliverGap(0) : SliverGap(96),
              buildPlayList(),
              SliverGap(12),
              buildAlbum(),
              SliverGap(12),
              buildMv(),
              SliverGap(12),
              buildSong(),
              SliverGap(12),
              buildTip(),
              SliverGap(12),
              SliverGap(bottom),
            ],
          )),
      left: Scaffold(
        backgroundColor: Colors.transparent,
        // floatingActionButton: context.width < 700
        //     ? Hidable(
        //         controller: scrollController,
        //         enableOpacityAnimation: true, // optional, defaults to `true`.
        //         child: Container(
        //           alignment: Alignment.bottomRight,
        //           child: PlayBar(),
        //         ),
        //       )
        //     : null,
        body: context.width < 700
            ? PageCustomScrollView(
                scrollController: scrollController,
                onRefresh: () {
                  controller.getData();
                  return Future.delayed(Duration(milliseconds: 500)).then((v) {
                    refreshController.finishRefresh(IndicatorResult.success, true);
                  });
                },
                slivers: [
                  buildAppBar(),
                  buildMenu(),
                  SliverGap(16),
                  buildPlayList(),
                  SliverGap(16),
                  buildAlbum(),
                  SliverGap(16),
                  buildMv(),
                  SliverGap(16),
                  buildSong(),
                  SliverGap(16),
                  buildTip(),
                  SliverGap(bottom),
                ],
                controller: refreshController,
              )
            : ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false, overscroll: false),
                child: CustomScrollView(
                  slivers: [
                    buildAppBar2(),
                    buildMenuList(),
                    SliverGap(12),
                    buildTip(),
                    SliverGap(12),
                    SliverGap(bottom),
                  ],
                )),
      ),
    )));
  }

  Widget buildAppBar() {
    return SliverAppBar.large(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: const Text("MixMusic"),
      actions: [
        IconButton(
            onPressed: () async {
              Get.toNamed(Routes.search);
            },
            icon: const Icon(Icons.search)),
        IconButton(
            onPressed: () async {
              Get.toNamed(Routes.download);
            },
            icon: const Icon(Icons.download)),
        IconButton(
            onPressed: () async {
              Get.toNamed(Routes.setting);
            },
            icon: const Icon(Icons.settings)),
      ],
    );
  }

  Widget buildAppBar2() {
    return context.isPhone
        ? SliverAppBar(
            surfaceTintColor: Colors.transparent,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text("MixMusic"),
          )
        : SliverAppBar.large(
            surfaceTintColor: Colors.transparent,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text("MixMusic"),
          );
  }

  Widget buildMenu() {
    return SliverToBoxAdapter(
      child: Container(
        alignment: Alignment.centerLeft,
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true, overscroll: true),
          child: ListView(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            children: [
              HyperCard(
                width: 90,
                height: 90,
                alpha: 0.7,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    child: GridTile(
                      header: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        alignment: Alignment.topLeft,
                        child: const Icon(Icons.recommend_sharp),
                      ),
                      footer: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        alignment: Alignment.bottomRight,
                        child: const Text("每日推荐"),
                      ),
                      child: Container(),
                    ),
                  ),
                  onTap: () {
                    Get.toNamed(Routes.recommend);
                  },
                ),
              ),
              Gap(12),
              HyperCard(
                width: 90,
                height: 90,
                alpha: 0.7,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    child: GridTile(
                      header: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        alignment: Alignment.topLeft,
                        child: const Icon(Icons.align_vertical_top_rounded),
                      ),
                      footer: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        alignment: Alignment.bottomRight,
                        child: const Text("排行"),
                      ),
                      child: Container(),
                    ),
                  ),
                  onTap: () {
                    Get.toNamed(Routes.rank);
                  },
                ),
              ),
              Gap(12),
              HyperCard(
                width: 90,
                height: 90,
                alpha: 0.7,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                      padding: EdgeInsets.all(4),
                      child: GridTile(
                        header: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          alignment: Alignment.topLeft,
                          child: const Icon(Icons.group_rounded),
                        ),
                        footer: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          alignment: Alignment.bottomRight,
                          child: const Text("歌手"),
                        ),
                        child: Container(),
                      )),
                  onTap: () {
                    Get.toNamed(Routes.artist);
                  },
                ),
              ),
              Gap(12),
              HyperCard(
                width: 90,
                height: 90,
                alpha: 0.7,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                      padding: EdgeInsets.all(4),
                      child: GridTile(
                        header: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          alignment: Alignment.topLeft,
                          child: const Icon(Icons.import_contacts),
                        ),
                        footer: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          alignment: Alignment.bottomRight,
                          child: const Text("导入"),
                        ),
                        child: Container(),
                      )),
                  onTap: () {
                    Get.toNamed(Routes.parsePlayList);
                  },
                ),
              ),
              Gap(12),
              HyperCard(
                width: 90,
                height: 90,
                alpha: 0.7,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                      padding: EdgeInsets.all(4),
                      child: GridTile(
                        header: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          alignment: Alignment.topLeft,
                          child: const Icon(Icons.history),
                        ),
                        footer: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          alignment: Alignment.bottomRight,
                          child: const Text("历史"),
                        ),
                        child: Container(),
                      )),
                  onTap: () {
                    Get.toNamed(Routes.appHistoryMusicList);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuList() {
    return SliverToBoxAdapter(
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.vertical,
          children: [
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: ListTile(
                    leading: Icon(Icons.search),
                    title: Text("搜索"),
                  ),
                ),
                onTap: () {
                  Get.toNamed(Routes.search);
                },
              ),
            ),
            Gap(12),
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: ListTile(
                    leading: Icon(Icons.recommend_sharp),
                    title: Text("每日推荐"),
                  ),
                ),
                onTap: () {
                  Get.toNamed(Routes.recommend);
                },
              ),
            ),
            Gap(12),
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: ListTile(
                    leading: const Icon(Icons.align_vertical_top_rounded),
                    title: const Text("排行"),
                  ),
                ),
                onTap: () {
                  Get.toNamed(Routes.rank);
                },
              ),
            ),
            Gap(12),
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: EdgeInsets.all(4),
                    child: ListTile(
                      leading: const Icon(Icons.group_rounded),
                      title: const Text("歌手"),
                    )),
                onTap: () {
                  Get.toNamed(Routes.artist);
                },
              ),
            ),
            Gap(12),
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: EdgeInsets.all(4),
                    child: ListTile(
                      leading: const Icon(Icons.import_contacts),
                      title: const Text("导入"),
                    )),
                onTap: () {
                  Get.toNamed(Routes.parsePlayList);
                },
              ),
            ),
            Gap(12),
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: EdgeInsets.all(4),
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text("历史"),
                    )),
                onTap: () {
                  Get.toNamed(Routes.appHistoryMusicList);
                },
              ),
            ),
            Gap(12),
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: EdgeInsets.all(4),
                    child: ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: const Text("下载"),
                    )),
                onTap: () {
                  Get.toNamed(Routes.download);
                },
              ),
            ),
            Gap(12),
            HyperCard(
              alpha: 0.7,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: EdgeInsets.all(4),
                    child: ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("设置"),
                    )),
                onTap: () {
                  Get.toNamed(Routes.setting);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlayList() {
    return HyperGroupBigTitle(
      title: "歌单",
      subTitle: "更多",
      alpha: 0.7,
      onTap: () {
        Get.toNamed(Routes.playList);
      },
      children: [
        Container(
          height: 140,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    return HyperCard(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 100,
                          height: 140,
                          child: Column(
                            children: [
                              Hero(
                                tag: "${item.package}${item.id}${item.pic}",
                                child: AppImage(url: item.pic ?? "", width: 100, height: 100, radius: 12),
                              ).expanded(),
                              Container(
                                height: 40,
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  item.title ?? "",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                        ),
                        onTap: () {
                          Get.toNamed(Routes.playListDetail, arguments: item);
                        },
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                )),
          ),
        ),
      ],
    );
  }

  Widget buildAlbum() {
    return HyperGroupBigTitle(
        title: "专辑",
        subTitle: "更多",
        alpha: 0.7,
        onTap: () {
          Get.toNamed(Routes.album);
        },
        children: [
          Container(
              height: 140,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      return HyperCard(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 100,
                            height: 140,
                            child: Column(
                              children: [
                                Hero(
                                  tag: "${item.package}${item.id}${item.pic}",
                                  child: AppImage(url: item.pic ?? "", width: 100, height: 100, radius: 12),
                                ).expanded(),
                                Container(
                                  height: 20,
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    item.title ?? "",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  height: 20,
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    item.subTitle ?? "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontSize: 12, fontWeight: FontWeight.w300),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                          onTap: () {
                            Get.toNamed(Routes.albumDetail, arguments: item);
                          },
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                  ),
                ),
              ))
        ]);
  }

  Widget buildMv() {
    return HyperGroupBigTitle(
        title: "MV",
        subTitle: "更多",
        alpha: 0.7,
        onTap: () {
          Get.toNamed(Routes.mv);
        },
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      return HyperCard(
                        borderRadius: BorderRadius.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Hero(
                                tag: "${item.package}${item.id}${item.pic}",
                                child: AppImage(url: item.pic ?? "", width: 178, height: 100, radius: 12),
                              ),
                              Container(
                                constraints: BoxConstraints(maxWidth: 178),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    color: Theme.of(context).colorScheme.surfaceContainer.withAlpha(200),
                                    child: Text(
                                      "${item.title}",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          onTap: () {
                            Get.toNamed(Routes.mvDetail, arguments: item);
                          },
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                  )),
            ),
          )
        ]);
  }

  Widget buildSong() {
    return Obx(
      () => HyperGroupBigTitle(
        title: "新歌",
        alpha: 0.7,
        children: [
          ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: controller.songList.length,
            itemBuilder: (BuildContext context, int index) {
              var song = controller.songList[index];
              return Obx(() => ListTile(
                    selected: controller.music.currentMusic.value?.id == song.id,
                    leading: HyperLeading(
                      size: 50,
                      child: AppImage(url: "${song.pic}"),
                    ),
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
                                child:
                                    const Text("VIP", maxLines: 1, style: TextStyle(fontSize: 10, color: Colors.green)),
                              )
                            : Container(),
                      ],
                    ),
                    subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
                    trailing: song.mv != null
                        ? IconButton(
                            onPressed: () {
                              Get.toNamed(Routes.mvDetail, arguments: song.mv);
                            },
                            icon: Icon(Icons.music_video))
                        : null,
                    onTap: () {
                      controller.music.playList(list: controller.songList, index: index);
                    },
                  ));
            },
          )
        ],
      ),
    );
  }

  Widget buildTip() {
    return Obx(
      () => SliverToBoxAdapter(
        child: Center(
          child: Text(
            "${controller.plugin.value?.name ?? "MixMusic"}提供数据支持",
            style: Theme.of(context).listTileTheme.subtitleTextStyle,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
