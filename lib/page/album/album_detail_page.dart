import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/hyper/hyper_song_item.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

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

  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _isVisible.value = true;
    });

    album.value = Get.arguments;

    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      getAlbumInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bottom = MediaQuery.of(context).padding.bottom;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      floatingActionButton: PlayBar(),
      body: PageCustomScrollView(
        controller: refreshController,
        onRefresh: () {
          return getAlbumInfo();
        },
        onLoad: () {
          return getAlbumInfo(page: pageEntity.value?.page ?? 0);
        },
        slivers: [
          SliverAppBar.large(
            title: Text(album.value?.title ?? ""),
            actions: [
              IconButton(
                  onPressed: () {
                    showDialog(
                      useRootNavigator: false,
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('关于'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppImage(url: album.value?.pic ?? "", width: 260, height: 260),
                              Gap(16),
                              Text(album.value?.desc ?? ""),
                            ],
                          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: const BorderRadius.all(Radius.circular(12))),
                child: ListTile(
                  title: Text("播放全部"),
                  trailing: Icon(Icons.play_arrow_rounded, size: 30),
                  onTap: () {
                    music.playList(list: songList, index: 0);
                  },
                ),
              ),
            ),
          ),
          Obx(
            () => SliverAnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: firstLoad.value
                  ? const SliverToBoxAdapter(
                      child: HyperLoading(height: 400),
                    )
                  : SliverList.builder(
                      // physics: const NeverScrollableScrollPhysics(),
                      // shrinkWrap: true,
                      // padding: const EdgeInsets.only(top: 0),
                      itemCount: songList.length,
                      itemBuilder: (BuildContext context, int index) {
                        var song = songList[index];
                        return HyperSongItem(
                          song: song,
                          onTap: () {
                            music.playList(list: songList, index: index);
                          },
                        );
                      },
                    ),
            ),
          ),
          SliverGap(bottom),
        ],
      ),
    );
  }

  ///获取专辑
  void getAlbumInfo({int page = 0}) {
    ApiFactory.api(package: album.value?.package ?? "")?.albumInfo(album: album.value!, page: page, size: 20).then((value) {
      firstLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        album.value = value.data;

        songList.clear();
        refreshController.finishRefresh();
      }
      Future.delayed(Duration(milliseconds: 200)).then((v) {
        refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
      });

      var songs = value.data?.songs ?? [];
      album.value?.songs = null;

      songList.addAll(songs.map((e) {
        e.album = album.value;
        return e;
      }));

      // showComplete("操作成功");
    }).catchError((e) {
      firstLoad.value = false;
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
