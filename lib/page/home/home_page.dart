import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/route/routes.dart';
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
      appBar: AppBar(
        leadingWidth: 0,
        leading: Container(width: 0),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(Routes.rank);
                      },
                      icon: const Icon(Icons.align_vertical_top_rounded),
                      label: Text("排行")),
                  ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(Routes.artist);
                      },
                      icon: const Icon(Icons.group_rounded),
                      label: Text("歌手")),
                  ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(Routes.parsePlayList);
                      },
                      icon: const Icon(Icons.import_contacts),
                      label: Text("导入")),
                ],
              ),
            ),

            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   alignment: Alignment.center,
            //   child: ClipRRect(
            //     borderRadius: const BorderRadius.all(Radius.circular(16)),
            //     child: CarouselSlider(
            //       options: CarouselOptions(
            //         autoPlay: true,
            //         aspectRatio: 16 / 6,
            //         viewportFraction: 1,
            //         enlargeCenterPage: true,
            //       ),
            //       items: [
            //         BlurRectWidget(
            //           color: Colors.grey.withOpacity(0.2),
            //           borderRadius: const BorderRadius.all(Radius.circular(16)),
            //         )
            //       ],
            //     ),
            //   ),
            // ),
            ListTile(
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
                    return InkWell(
                      child: SizedBox(
                        width: 80,
                        height: 140,
                        child: Column(
                          children: [
                            AppImage(url: item.pic ?? "", width: 80).expanded(),
                            Container(
                              height: 40,
                              child: Text(
                                item.title ?? "",
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
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 16),
                ),
              ),
            ),
            ListTile(
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
            Container(
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
                        width: 80,
                        height: 140,
                        child: Column(
                          children: [
                            AppImage(url: item.pic ?? "", width: 80).expanded(),
                            Container(
                              height: 40,
                              child: Text(
                                item.title ?? "",
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
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 16),
                ),
              ),
            ),
            ListTile(
              title: Text("新歌", style: Theme.of(context).textTheme.titleLarge),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            Obx(
              () => ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: controller.songList.length,
                shrinkWrap: true,
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
            Gap(bottom),
          ],
        ),
      ),
    );
  }
}
