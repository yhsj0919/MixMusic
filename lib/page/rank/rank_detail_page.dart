import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/widgets/hidable/hidable_widget.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_rank.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../entity/page_entity.dart';
import '../../player/music_controller.dart';
import '../../widgets/message.dart';

class RankDetailPage extends StatefulWidget {
  const RankDetailPage({super.key});

  @override
  State<RankDetailPage> createState() => _RankDetailPageState();
}

class _RankDetailPageState extends State<RankDetailPage> {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  RxList<MixSong> songList = RxList();
  Rxn<PageEntity> pageEntity = Rxn();
  Rxn<MixRank> rank = Rxn();
  final RxBool _isVisible = RxBool(false);
  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _isVisible.value = true;
    });
    rank.value = Get.arguments;
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    Future.delayed(const Duration(milliseconds: 300)).then((v) {
      getRankInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double width = MediaQuery.of(context).size.width;
    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight;
    return Scaffold(
        floatingActionButton: PlayBar(),
        body: PageCustomScrollView(
          controller: refreshController,
          onRefresh: () {
            return getRankInfo();
          },
          onLoad: () {
            return getRankInfo(page: pageEntity.value?.page ?? 0);
          },
          slivers: [
            SliverAppBar.large(
              title: Text(rank.value?.title ?? ""),
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
                                AppImage(url: rank.value?.pic ?? "", width: 260, height: 260),
                                Gap(16),
                                Text(rank.value?.desc ?? ""),
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
                                trailing: song.mv != null
                                    ? IconButton(
                                        onPressed: () {
                                          Get.toNamed(Routes.mvDetail, arguments: song.mv);
                                        },
                                        icon: Icon(Icons.music_video))
                                    : null,
                                onTap: () {
                                  music.playList(list: songList, index: index);
                                },
                              ));
                        },
                      ),
              ),
            )
          ],
        ));
  }

  ///获取专辑
  void getRankInfo({int page = 0}) {
    ApiFactory.api(package: rank.value?.package ?? "")?.rankInfo(rank: rank.value!, page: page, size: 20).then((value) {
      firstLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        rank.value = value.data;
        songList.clear();
        refreshController.finishRefresh();
      }
      Future.delayed(Duration(milliseconds: 200)).then((v) {
        refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
      });

      var songs = value.data?.songs ?? [];
      songList.addAll(songs);
      rank.value?.songs = null;

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
