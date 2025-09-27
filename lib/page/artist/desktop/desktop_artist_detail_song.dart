import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_artist.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/fluent/Fluent_song_item.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_list_view.dart';

class DesktopArtistDetailSong extends StatefulWidget {
  const DesktopArtistDetailSong({super.key, required this.artist});

  final MixArtist artist;

  @override
  State<DesktopArtistDetailSong> createState() => _DesktopArtistDetailSongState();
}

class _DesktopArtistDetailSongState extends State<DesktopArtistDetailSong> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixSong> songList = RxList();
  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);

    Future.delayed(const Duration(milliseconds: 300)).then((v) {
      artistSong(artist: widget.artist);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: firstLoad.value
            ? const HyperLoading()
            : PageListView(
                controller: refreshController,
                onRefresh: () {
                  return artistSong(artist: widget.artist);
                },
                onLoad: () {
                  return artistSong(artist: widget.artist, page: pageEntity.value?.page ?? 0);
                },
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
    );
  }

  ///获取歌单
  void artistSong({required MixArtist artist, int page = 0}) {
    ApiFactory.api(package: widget.artist.package)
        ?.artistSong(artist: artist, page: page, size: 20)
        .then((value) {
          firstLoad.value = false;
          pageEntity.value = value.page;
          if (page == 0) {
            songList.clear();
            refreshController.finishRefresh();
          }
          Future.delayed(Duration(milliseconds: 200)).then((v) {
            refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
          });

          songList.addAll(value.data ?? []);

          // showComplete("操作成功");
        })
        .catchError((e) {
          firstLoad.value = false;
          if (page == 0) {
            refreshController.finishRefresh(IndicatorResult.fail, true);
          } else {
            refreshController.finishLoad(IndicatorResult.fail, true);
          }
          showError(e);
        });
  }

  @override
  bool get wantKeepAlive => true;
}
