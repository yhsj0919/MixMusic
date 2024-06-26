import 'dart:math';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/app_image.dart';

import '../../entity/page_entity.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import '../../player/music_controller.dart';
import '../../widgets/message.dart';
import '../../widgets/page_list_view.dart';
import '../api_controller.dart';

class AlbumDetailPage extends StatefulWidget {
 const AlbumDetailPage({super.key});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  RxList<MixSong> songList = RxList();
  ApiController api = Get.put(ApiController());
  Rxn<PageEntity> pageEntity = Rxn();
  Rxn<MixAlbum> album = Rxn();

  @override
  void initState() {
    super.initState();
    album.value = Get.arguments;
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    getAlbumInfo();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight;
    return Scaffold(
      floatingActionButton: PlayBar(),
      body: ExtendedNestedScrollView(
        headerSliverBuilder: (BuildContext c, bool f) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    album.value?.title ?? "专辑",
                    style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                    maxLines: f ? 1 : null,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // collapseMode: CollapseMode.parallax,
                  background: Stack(
                    children: [
                      AppImage(
                        url: album.value?.pic ?? "",
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width,
                        animationDuration: 0,
                        radius: 0,
                      ),
                      BlurRectWidget(border: Border.all(color: Colors.transparent)),
                    ],
                  )),
              forceElevated: f,
              pinned: true,
              actions: [
                IconButton(
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
                    icon: const Icon(Icons.info_outline_rounded))
              ],
            ),
            SliverPersistentHeader(
                pinned: true,
                delegate: _SliverDelegate(
                    minHeight: 50,
                    maxHeight: 50,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.all(Radius.circular(16))),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle, color: Theme.of(context).colorScheme.primary),
                          TextButton(
                              onPressed: () {
                                music.playList(list: songList, index: 0);
                              },
                              child: const Text("播放全部")),
                          Obx(() => Text("${songList.length}/${album.value?.songCount ?? "0"}")),
                        ],
                      ),
                    ))),
            SliverPersistentHeader(pinned: true, delegate: _SliverDelegate(minHeight: 1, maxHeight: 1, child: Container(color: Theme.of(context).dividerColor.withOpacity(0.2)))),
          ];
        },
        pinnedHeaderSliverHeightBuilder: () {
          return pinnedHeaderHeight;
        },
        onlyOneScrollInBody: true,
        // physics: NeverScrollableScrollPhysics(),
        body: Obx(
          () => PageListView(
            controller: refreshController,
            onRefresh: () {
              return getAlbumInfo();
            },
            onLoad: () {
              return getAlbumInfo(page: pageEntity.value?.page ?? 0);
            },
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
        ),
      ),
    );
  }

  ///获取专辑
  Future<void> getAlbumInfo({int page = 0}) {
    return api.albumInfo(site: album.value?.site ?? "", album: album.value!, page: page).then((value) {
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

class _SliverDelegate extends SliverPersistentHeaderDelegate {
  _SliverDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight; //最小高度
  final double maxHeight; //最大高度
  final Widget child; //孩子

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override //是否需要重建
  bool shouldRebuild(_SliverDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
