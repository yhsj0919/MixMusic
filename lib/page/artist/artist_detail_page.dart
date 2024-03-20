import 'dart:math';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_artist.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/artist/artist_detail_album.dart';
import 'package:mix_music/page/artist/artist_detail_song.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/page_list_view.dart';

import '../../entity/page_entity.dart';
import '../../player/music_controller.dart';
import '../../widgets/message.dart';
import '../api_controller.dart';

class ArtistDetailPage extends StatefulWidget {
  ArtistDetailPage({super.key, required this.artist});

  MixArtist? artist;

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> with TickerProviderStateMixin {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  RxList<MixSong> songList = RxList();
  ApiController api = Get.put(ApiController());
  Rxn<PageEntity> pageEntity = Rxn();
  Rxn<MixArtist> artist = Rxn();

  late TabController tabController;

  RxList<String> detailMethod = RxList();

  @override
  void initState() {
    super.initState();

    detailMethod.addAll(api.getArtistDetailMethod(widget.artist?.site));

    tabController = TabController(length: detailMethod.length, vsync: this);

    artist.value = widget.artist;
    refreshController = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
    getPlayListInfo();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight;
    return Scaffold(
      body: ExtendedNestedScrollView(
        headerSliverBuilder: (BuildContext c, bool f) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    artist.value?.name ?? "歌手",
                    style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                    maxLines: f ? 1 : null,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // collapseMode: CollapseMode.parallax,
                  background: Stack(
                    children: [
                      AppImage(
                        url: artist.value?.pic ?? "",
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
                            content: Text(artist.value?.desc ?? ""),
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: TabBar(
                    // 指示器颜色
                    controller: tabController,
                    isScrollable: true,
                    tabs: detailMethod.map((element) {
                      if (element == "artistSong") {
                        return const Tab(text: "歌曲");
                      }
                      if (element == "artistAlbum") {
                        return const Tab(text: "专辑");
                      }
                      if (element == "artistMv") {
                        return const Tab(text: "MV");
                      }

                      return const Tab(text: "未知");
                    }).toList(),
                  ),
                ),
              ),
            ),
          ];
        },
        pinnedHeaderSliverHeightBuilder: () {
          return pinnedHeaderHeight;
        },
        onlyOneScrollInBody: true,
        // physics: NeverScrollableScrollPhysics(),
        body: Column(
          children: <Widget>[Expanded(child: _buildTabBarView())],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: detailMethod.map((element) {
        if (element == "artistSong") {
          return ArtistDetailSong(artist: artist.value!);
        }
        if (element == "artistAlbum") {
          return ArtistDetailAlbum(artist: artist.value!);
        }

        return const Center(child: Text("未知"));
      }).toList(),
    );
  }

  ///获取歌单
  Future<void> getPlayListInfo({int page = 0}) {
    return Future(() => null);
    // return api.playListInfo(site: artist.value?.site ?? "", playlist: playlist.value!, page: page).then((value) {
    //   pageEntity.value = value.page;
    //   if (page == 0) {
    //     songList.clear();
    //     refreshController.finishRefresh();
    //   }
    //   refreshController.finishLoad((pageEntity.value?.last != null && pageEntity.value?.last == true) ? IndicatorResult.noMore : IndicatorResult.success, true);
    //
    //   if (pageEntity.value != null) {
    //     songList.addAll(value.data?.songs ?? []);
    //   }
    //   // showComplete("操作成功");
    // }).catchError((e) {
    //   if (page == 0) {
    //     refreshController.finishRefresh(IndicatorResult.fail, true);
    //   } else {
    //     refreshController.finishLoad(IndicatorResult.fail, true);
    //   }
    //   showError(e);
    // });
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
