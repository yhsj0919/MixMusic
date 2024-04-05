import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/app_image.dart';

import '../../entity/mix_play_list.dart';
import '../../widgets/message.dart';
import '../api_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MusicController music = Get.put(MusicController());
  ApiController api = Get.put(ApiController());
  RxList<MixPlaylist> playlist = RxList();
  RxList<MixAlbum> albumList = RxList();

  @override
  void initState() {
    super.initState();
    getNewPlayList();
    getNewAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: Container(width: 0),
        title: const Text("MixMusic"),
        actions: [
          IconButton(
              onPressed: () async {
                Get.toNamed(Routes.search, id: Routes.key);
              },
              icon: const Icon(Icons.search)),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Get.toNamed(Routes.rank, id: Routes.key);
                      },
                      icon: const Icon(Icons.align_vertical_top_rounded)),
                  IconButton(
                      onPressed: () {
                        Get.toNamed(Routes.artist, id: Routes.key);
                      },
                      icon: const Icon(Icons.person)),
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
              title: const Text("歌单"),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {
                  Get.toNamed(Routes.playList, id: Routes.key);
                },
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),

            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: playlist.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    var item = playlist[index];
                    return InkWell(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            AppImage(url: item.pic ?? "", width: 80, height: 80),
                            BlurRectWidget(
                              width: 80,
                              height: 25,
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                              child: Center(
                                child: Text(item.title ?? "", maxLines: 1),
                              ),
                            )
                          ],
                        ),
                      ),
                      onTap: () {
                        Get.toNamed(Routes.playListDetail, arguments: item, id: Routes.key);
                      },
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
                ),
              ),
            ),
            ListTile(
              title: const Text("专辑"),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {
                  Get.toNamed(Routes.album, id: Routes.key);
                },
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: albumList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    var item = albumList[index];
                    return InkWell(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            AppImage(url: item.pic ?? "", width: 80, height: 80),
                            BlurRectWidget(
                              width: 80,
                              height: 25,
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                              child: Center(
                                child: Text(item.title ?? "", maxLines: 1),
                              ),
                            )
                          ],
                        ),
                      ),
                      onTap: () {
                        Get.toNamed(Routes.albumDetail, arguments: item, id: Routes.key);
                      },
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
                ),
              ),
            ),
            ListTile(
              title: const Text("新歌"),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 10,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    width: 45,
                    height: 45,
                  ),
                  title: Text("歌名$index"),
                  subtitle: Text("歌手"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ///获取歌单
  Future<void> getNewPlayList() {
    return api.newPlayList(site: api.newPlugins.first.site ?? "").then((value) {
      playlist.clear();
      playlist.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }

  ///获取专辑
  Future<void> getNewAlbum() {
    return api.newAlbum(site: api.newPlugins.first.site ?? "").then((value) {
      albumList.clear();
      albumList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }
}
