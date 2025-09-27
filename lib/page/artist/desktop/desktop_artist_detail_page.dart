import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_artist.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/FluentMouseWidget.dart';

import 'desktop_artist_detail_album.dart';
import 'desktop_artist_detail_song.dart';

class DesktopArtistDetailPage extends StatefulWidget {
  const DesktopArtistDetailPage({super.key, required this.item});

  final MixArtist item;

  @override
  State<DesktopArtistDetailPage> createState() => _DesktopArtistDetailPageState();
}

class _DesktopArtistDetailPageState extends State<DesktopArtistDetailPage> with TickerProviderStateMixin {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  RxList<MixSong> songList = RxList();
  Rxn<PageEntity> pageEntity = Rxn();
  Rxn<MixArtist> artist = Rxn();

  RxList<String> detailMethod = RxList();
  final RxBool _isVisible = RxBool(false);
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _isVisible.value = true;
    });

    artist.value = widget.item;

    detailMethod.addAll(ApiFactory.getArtistMethod(artist.value?.package));

    refreshController = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
    getPlayListInfo();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        height: 132,
        child: Card(
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
                          child: AppImage(url: artist.value?.pic ?? "", width: 200, height: 200),
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
                        artist.value?.title ?? "",
                        style: FluentTheme.of(context).typography.titleLarge?.copyWith(fontWeight: FontWeight.normal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(artist.value?.desc ?? "", style: FluentTheme.of(context).typography.subtitle?.copyWith(fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      content: TabView(
        header: Container(),
        tabs: detailMethod.map((element) {
          return Tab(
            text: Text(
              element == "song"
                  ? "歌曲"
                  : element == "album"
                  ? "专辑"
                  : element == "mv"
                  ? "MV"
                  : "未知",
            ),
            selectedBackgroundColor: WidgetStateProperty.all((FluentTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white).withValues(alpha: 0.1)),
            icon: Icon(
              element == "song"
                  ? FluentIcons.music_note
                  : element == "album"
                  ? WindowsIcons.music_album
                  : element == "mv"
                  ? FluentIcons.my_movies_t_v
                  : FluentIcons.music_note,
            ),
            body: element == "song"
                ? DesktopArtistDetailSong(artist: artist.value!)
                : element == "album"
                ? DesktopArtistDetailAlbum(artist: artist.value!)
                : element == "mv"
                ? Container()
                : Container(),
          );
        }).toList(),
        currentIndex: currentIndex,
        onChanged: (index) => setState(() => currentIndex = index),
        tabWidthBehavior: TabWidthBehavior.sizeToContent,
        closeButtonVisibility: CloseButtonVisibilityMode.always,
        showScrollButtons: true,
      ),
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
    //         Future.delayed(Duration(milliseconds: 200)).then((v) {
    //refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
    // });
    //

    //     songList.addAll(value.data?.songs ?? []);
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
