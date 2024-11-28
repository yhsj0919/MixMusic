import 'dart:math';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_artist.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/page/artist/artist_detail_album.dart';
import 'package:mix_music/page/artist/artist_detail_song.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';

import '../../entity/page_entity.dart';
import '../../player/music_controller.dart';

class ArtistDetailPage extends StatefulWidget {
  const ArtistDetailPage({super.key});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> with TickerProviderStateMixin {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  RxList<MixSong> songList = RxList();
  Rxn<PageEntity> pageEntity = Rxn();
  Rxn<MixArtist> artist = Rxn();

  late TabController tabController;

  RxList<String> detailMethod = RxList();
  final RxBool _isVisible = RxBool(false);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _isVisible.value = true;
    });

    artist.value = Get.arguments;

    detailMethod.addAll(ApiFactory.getArtistMethod(artist.value?.package));

    tabController = TabController(length: detailMethod.length, vsync: this);

    refreshController = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
    getPlayListInfo();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double width = MediaQuery.of(context).size.width;

    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight;
    return Scaffold(
      floatingActionButton: PlayBar(),
      body: ExtendedNestedScrollView(
        headerSliverBuilder: (BuildContext c, bool f) {
          return [
            HyperAppbar(
              title: artist.value?.title ?? "",
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0), // 设置圆角的大小
                            ),
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
            PinnedHeaderSliver(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: TabBar(
                  // 指示器颜色
                  controller: tabController,
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isScrollable: true,
                  tabs: detailMethod.map((element) {
                    if (element == "song") {
                      return const Tab(text: "歌曲");
                    }
                    if (element == "album") {
                      return const Tab(text: "专辑");
                    }
                    if (element == "mv") {
                      return const Tab(text: "MV");
                    }

                    return const Tab(text: "未知");
                  }).toList(),
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
        if (element == "song") {
          return ArtistDetailSong(artist: artist.value!);
        }
        if (element == "album") {
          return ArtistDetailAlbum(artist: artist.value!);
        }

        return const Center(child: Text("未知"));
      }).toList(),
    );
  }

  ///获取歌单
  Future<void> getPlayListInfo({int page = 0}) {
    return Future(() => null);
    // return api.playListInfo(site: artist.value?.package  ?? "", playlist: playlist.value!, page: page).then((value) {
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
