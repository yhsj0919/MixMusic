import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/SliverDelegate.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/FluentMouseWidget.dart';
import 'package:mix_music/widgets/fluent/Fluent_song_item.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DesktopAlbumDetailPage extends StatefulWidget {
  const DesktopAlbumDetailPage({super.key, required this.item});

  final MixAlbum item;

  @override
  State<DesktopAlbumDetailPage> createState() => _DesktopAlbumDetailPageState();
}

class _DesktopAlbumDetailPageState extends State<DesktopAlbumDetailPage> {
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

    album.value = widget.item;

    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      getAlbumInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: PageCustomScrollView(
        controller: refreshController,
        onRefresh: () {
          return getAlbumInfo();
        },
        onLoad: () {
          return getAlbumInfo(page: pageEntity.value?.page ?? 0);
        },
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverPersistentHeader(
              pinned: true, // 是否固定头部
              floating: false, // 是否允许头部随着滚动浮动
              delegate: SliverDelegate(
                minHeight: 100 + 32,
                maxHeight: 200,
                builder: (double offset) {
                  return Card(
                    backgroundColor: FluentTheme.of(context).brightness == Brightness.light ? Colors.white : Color(0xff1a2227),

                    child: Row(
                      children: [
                        FluentMouseWidget(
                          builder: (bool hover) {
                            return Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Hero(
                                    tag: "${widget.item.package}${widget.item.id}${widget.item.pic}",
                                    child: AppImage(url: album.value?.pic ?? "", width: 200, height: 200),
                                  ),
                                ),
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: GestureDetector(
                                    onTap: hover
                                        ? () {
                                            context.pop();
                                          }
                                        : null,
                                    child: AnimatedContainer(
                                      decoration: BoxDecoration(color: hover ? Colors.black.withAlpha((255 * 0.6).toInt()) : null, borderRadius: BorderRadius.circular(8)),
                                      duration: Duration(milliseconds: 200),
                                      child: hover ? Icon(FluentIcons.back, color: Colors.white, size: 30) : null,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Gap(16),
                        Expanded(
                          child: Column(
                            spacing: 16,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  album.value?.title ?? "",
                                  style: FluentTheme.of(context).typography.titleLarge?.copyWith(fontWeight: FontWeight.normal),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (offset < 35)
                                Text(
                                  album.value?.artist?.map((item) => item.title).join("、") ?? "",
                                  style: FluentTheme.of(context).typography.subtitle?.copyWith(fontWeight: FontWeight.normal),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (offset < 2)
                                Obx(
                                  () => Text("${album.value?.songCount ?? "0"}首歌", style: FluentTheme.of(context).typography.bodyStrong?.copyWith(fontWeight: FontWeight.normal)),
                                ),
                              Row(
                                spacing: 16,
                                children: [
                                  Button(
                                    child: Row(spacing: 4, children: [Icon(FluentIcons.play), Text("全部播放")]),
                                    onPressed: () {
                                      music.playList(list: songList, index: 0);
                                    },
                                  ),
                                  Button(
                                    child: Row(spacing: 4, children: [Icon(FluentIcons.add), Text("添加到")]),
                                    onPressed: () {
                                      showFluentInfo(context, "暂未实现");
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverGap(32),
          Obx(
            () => SliverAnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: firstLoad.value
                  ? const SliverToBoxAdapter(child: HyperLoading(height: 400))
                  : SliverList.builder(
                      // physics: const NeverScrollableScrollPhysics(),
                      // shrinkWrap: true,
                      // padding: const EdgeInsets.only(top: 0),
                      itemCount: songList.length,
                      itemBuilder: (BuildContext context, int index) {
                        var song = songList[index];
                        return FluentSongItem(
                          song: song,
                          onTap: () {
                            music.playList(list: songList, index: index);
                          },
                          index: index,
                        );
                      },
                    ),
            ),
          ),
          SliverGap(6),
        ],
      ),
    );
  }

  ///获取专辑
  void getAlbumInfo({int page = 0}) {
    ApiFactory.api(package: album.value?.package ?? "")
        ?.albumInfo(album: album.value!, page: page, size: 20)
        .then((value) {
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

          songList.addAll(
            songs.map((e) {
              e.album = album.value;
              return e;
            }),
          );

          // showComplete("操作成功");
        })
        .catchError((e) {
          firstLoad.value = false;
          print(e);
          if (page == 0) {
            refreshController.finishRefresh(IndicatorResult.fail, true);
          } else {
            refreshController.finishLoad(IndicatorResult.fail, true);
          }
          showFluentError(context, e);
        });
  }
}
