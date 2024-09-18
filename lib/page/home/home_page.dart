import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/playlist/play_list_detail_page.dart';
import 'package:mix_music/page/playlist/playlist_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';

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
              title: const Text("MixMusic"),
              actions: [
                IconButton(
                    onPressed: () async {
                      Get.toNamed(Routes.search);
                    },
                    icon: const Icon(Icons.search)),
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
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Card.outlined(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
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
                          onTap: () {
                            Get.toNamed(Routes.rank);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Card.outlined(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
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
                          ),
                          onTap: () {
                            Get.toNamed(Routes.artist);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Card.outlined(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
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
                          ),
                          onTap: () {
                            Get.toNamed(Routes.parsePlayList);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ListTile(
                title: Text("歌单", style: Theme.of(context).textTheme.titleLarge),
                contentPadding: const EdgeInsets.only(left: 16),
                trailing: IconButton(
                  onPressed: () {
                    Get.toNamed(Routes.playList);
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_right_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 140,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.playlist.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      var item = controller.playlist[index];
                      return InkWell(
                        child: SizedBox(
                          width: 100,
                          height: 140,
                          child: Column(
                            children: [
                              Hero(
                                  tag: "${item.package}${item.id}${item.pic}",
                                  child: Card.outlined(
                                    child: AppImage(url: item.pic ?? "", width: 100, radius: 12),
                                  )).expanded(),
                              SizedBox(
                                height: 40,
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
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ListTile(
                title: Text("专辑", style: Theme.of(context).textTheme.titleLarge),
                contentPadding: const EdgeInsets.only(left: 16),
                trailing: IconButton(
                  onPressed: () {
                    Get.toNamed(Routes.album);
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_right_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
                child: Container(
              height: 140,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.albumList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    var item = controller.albumList[index];
                    return InkWell(
                      child: SizedBox(
                        width: 100,
                        height: 140,
                        child: Column(
                          children: [
                            Hero(
                                tag: "${item.package}${item.id}${item.pic}",
                                child: Card.outlined(
                                  child: AppImage(url: item.pic ?? "", width: 100, radius: 12),
                                )).expanded(),
                            SizedBox(
                              height: 40,
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
                        Get.toNamed(Routes.albumDetail, arguments: item);
                      },
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
                ),
              ),
            )),
            SliverToBoxAdapter(
                child: ListTile(
              title: Text("新歌", style: Theme.of(context).textTheme.titleLarge),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            )),
            Obx(
              () => SliverList.builder(
                itemCount: controller.songList.length,
                itemBuilder: (BuildContext context, int index) {
                  var song = controller.songList[index];
                  return Obx(() => ListTile(
                        selected: controller.music.currentMusic.value?.id == song.id,
                        leading: AppImage(url: song.pic ?? ""),
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
              ),
            ),
            SliverGap(bottom),
          ],
        ));
  }
}
