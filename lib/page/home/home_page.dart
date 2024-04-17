import 'package:drop_shadow/drop_shadow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';

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
  RxList<MixSong> songList = RxList();

  @override
  void initState() {
    super.initState();
    getPlayListRec();
    getAlbumRec();
    getSongRec();
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
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                alignment: WrapAlignment.start,
                // spacing: 8,
                // runSpacing: 8,
                children: [
                  DropShadow(
                    blurRadius: 6,
                    child: InkWell(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        width: 140,
                        height: 80,
                        alignment: Alignment.center,
                        child: const Text("排行榜"),
                      ),
                      onTap: () {
                        Get.toNamed(Routes.rank, id: Routes.key);
                      },
                    ),
                  ),
                  DropShadow(
                    blurRadius: 6,
                    child: InkWell(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        width: 140,
                        height: 80,
                        alignment: Alignment.center,
                        child: const Text("歌手"),
                      ),
                      onTap: () {
                        Get.toNamed(Routes.artist, id: Routes.key);
                      },
                    ),
                  ),
                  DropShadow(
                    blurRadius: 6,
                    child: InkWell(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        width: 140,
                        height: 80,
                        alignment: Alignment.center,
                        child: const Text("导入歌单"),
                      ),
                      onTap: () {
                        Get.toNamed(Routes.parsePlayList, id: Routes.key);
                      },
                    ),
                  ),
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
                  Get.toNamed(Routes.playList, id: Routes.key);
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
                  itemCount: playlist.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    var item = playlist[index];
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
                        Get.toNamed(Routes.playListDetail, arguments: item, id: Routes.key);
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
                  Get.toNamed(Routes.album, id: Routes.key);
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
                  itemCount: albumList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    var item = albumList[index];
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
                        Get.toNamed(Routes.albumDetail, arguments: item, id: Routes.key);
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
                itemCount: songList.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  var song = songList[index];
                  return Obx(() => ListTile(
                        selected: music.currentMusic.value?.id == song.id,
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
                          music.playList(list: songList, index: index);
                        },
                      ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///获取歌单
  Future<void> getPlayListRec() {
    return api.playListRec(site: api.recPlugins.firstOrNull?.site ?? "").then((value) {
      playlist.clear();
      playlist.addAll(value?.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }

  ///获取专辑
  Future<void> getAlbumRec() {
    return api.albumRec(site: api.recPlugins.firstOrNull?.site ?? "").then((value) {
      albumList.clear();
      albumList.addAll(value?.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }

  ///获取新歌
  Future<void> getSongRec() {
    return api.songRec(site: api.recPlugins.firstOrNull?.site ?? "").then((value) {
      songList.clear();
      songList.addAll(value?.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }
}
