import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/page_sliver_view.dart';

import '../../entity/page_entity.dart';
import '../../player/music_controller.dart';
import '../../widgets/message.dart';

class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  RxList<MixSong> songList = RxList();
  Rxn<PageEntity> pageEntity = Rxn();
  Rxn<MixAlbum> album = Rxn();

  final RxBool _isVisible = RxBool(false);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _isVisible.value = true;
    });

    album.value = Get.arguments;

    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      getAlbumInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      floatingActionButton: PlayBar(),
      body: Stack(children: [
        Obx(
          () => PageSliverView(
            controller: refreshController,
            onRefresh: () {
              return getAlbumInfo();
            },
            onLoad: () {
              return getAlbumInfo(page: pageEntity.value?.page ?? 0);
            },
            slivers: [
              SliverAppBar.large(
                expandedHeight: 240,
                surfaceTintColor: Colors.transparent,
                leading: Container(),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Hero(
                          tag: "${album.value?.package}${album.value?.id}${album.value?.pic}",
                          child: Container(
                              margin: EdgeInsets.only(left: 16, right: 16, top: statusBarHeight + 4, bottom: 0),
                              height: 240,
                              width: width,
                              child: AppImage(
                                url: album.value?.pic ?? "",
                                radius: 24,
                                width: width,
                              ))),
                      Container(
                          margin: const EdgeInsets.only(right: 24, bottom: 8),
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.bottomRight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              child: Obx(() => Text("${songList.length}/${album.value?.songCount ?? "0"}")),
                            ),
                          )),
                    ],
                  ),
                ),
                // title: Text("专辑"),
              ),
              PinnedHeaderSliver(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.all(Radius.circular(16))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.value?.title ?? "",
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              album.value?.artist?.map((v) => v.name).join(",") ?? "",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 16),
                      IconButton.filledTonal(
                          onPressed: () {
                            music.playList(list: songList, index: 0);
                          },
                          icon: const SizedBox(width: 100, height: 30, child: Icon(Icons.play_arrow_rounded, size: 30))),
                      // Container(width: 8),
                    ],
                  ),
                ),
              ),
              PinnedHeaderSliver(
                child: Container(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              ),
              SliverList.builder(
                itemCount: songList.length,
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
                        subtitle: Text(
                          song.subTitle ?? "",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        onTap: () {
                          music.playList(list: songList, index: index);
                        },
                      ));
                },
              ),
            ],
          ),
        ),
        Obx(() => AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isVisible.value ? 1.0 : 0.0,
            child: Row(
              children: [
                Container(
                  height: 64,
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.only(top: statusBarHeight),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: IconButton.filledTonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded)),
                ),
                Expanded(child: Container(height: 1)),
                Container(
                    height: 64,
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.only(top: statusBarHeight),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: IconButton.filledTonal(
                        onPressed: () {
                          showDialog(
                            useRootNavigator: false,
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('关于'),
                                content: Text(album.value?.desc ?? ""),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // 关闭对话框
                                    },
                                    child: const Text('关闭'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.info_outline_rounded)))
              ],
            ))),
      ]),
    );
  }

  ///获取专辑
  void getAlbumInfo({int page = 0}) {
    ApiFactory.api(package: album.value?.package ?? "")?.albumInfo(album: album.value!, page: page, size: 20).then((value) {
      pageEntity.value = value.page;
      if (page == 0) {
        album.value = value.data;

        songList.clear();
        refreshController.finishRefresh();
      }
      refreshController.finishLoad((pageEntity.value?.last != null && pageEntity.value?.last == true) ? IndicatorResult.noMore : IndicatorResult.success, true);

      var songs = value.data?.songs ?? [];
      album.value?.songs = null;

      songList.addAll(songs.map((e) {
        e.album = album.value;
        return e;
      }));

      // showComplete("操作成功");
    }).catchError((e) {
      print(e);
      if (page == 0) {
        refreshController.finishRefresh(IndicatorResult.fail, true);
      } else {
        refreshController.finishLoad(IndicatorResult.fail, true);
      }
      showError(e);
    });
  }
}
