import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/download/download_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';
import 'package:mix_music/widgets/hyper/hyper_card.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_group_big_title.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

import '../app_playing/play_bar.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeController controller = Get.put(HomeController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 获取状态栏的高度
    double statusBarHeight = max(MediaQuery.of(context).padding.top, 16);
    double bottom = max(MediaQuery.of(context).padding.bottom, 16);
    return Scaffold(
        floatingActionButton: PlayBar(),
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
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
                      Navigator.of(context).push(OpacityRoute(
                        builder: (BuildContext context) => DownloadPage(),
                      ));
                    },
                    icon: const Icon(Icons.download)),
                IconButton(
                    onPressed: () async {
                      Get.toNamed(Routes.setting);
                    },
                    icon: const Icon(Icons.settings)),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    HyperCard(
                      width: 100,
                      height: 100,
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
                    HyperCard(
                      width: 100,
                      height: 100,
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
                    HyperCard(
                      width: 100,
                      height: 100,
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
                  ],
                ),
              ),
            ),
            SliverGap(16),
            HyperGroupBigTitle(
              title: "歌单",
              subTitle: "更多",
              onTap: () {
                Get.toNamed(Routes.playList);
              },
              children: [
                Container(
                  height: 140,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(
                    () => ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.playlist.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        var item = controller.playlist[index];
                        return HyperCard(
                          borderRadius: BorderRadius.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 92,
                              height: 140,
                              child: Column(
                                children: [
                                  Hero(
                                    tag: "${item.package}${item.id}${item.pic}",
                                    child: AppImage(url: item.pic ?? "", width: 100, radius: 12),
                                  ).expanded(),
                                  Container(
                                    height: 40,
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      item.title ?? "",
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w300),
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
                    ),
                  ),
                ),
              ],
            ),
            SliverGap(16),
            HyperGroupBigTitle(
                title: "专辑",
                subTitle: "更多",
                onTap: () {
                  Get.toNamed(Routes.album);
                },
                children: [
                  Container(
                    height: 140,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Obx(
                      () => ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.albumList.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (BuildContext context, int index) {
                          var item = controller.albumList[index];
                          return HyperCard(
                            borderRadius: BorderRadius.zero,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 92,
                                height: 140,
                                child: Column(
                                  children: [
                                    Hero(
                                      tag: "${item.package}${item.id}${item.pic}",
                                      child: AppImage(url: item.pic ?? "", width: 100, radius: 12),
                                    ).expanded(),
                                    Container(
                                      height: 40,
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Text(
                                        item.title ?? "",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w300),
                                        maxLines: 2,
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
                  )
                ]),
            SliverGap(16),
            Obx(
              () => HyperGroupBigTitle(title: "新歌", children: [
                ListView.builder(
                  padding: EdgeInsets.all(0),
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
                                      child: const Text("VIP", maxLines: 1, style: TextStyle(fontSize: 10, color: Colors.green)),
                                    )
                                  : Container(),
                            ],
                          ),
                          subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
                          onTap: () {
                            controller.music.playList(list: controller.songList, index: index);
                          },
                        ));
                  },
                )
              ]),
            ),
            SliverGap(bottom),
          ],
        ));
  }
}
