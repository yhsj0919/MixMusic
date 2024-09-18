import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_artist.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/message.dart';

import '../../widgets/page_list_view.dart';

class ArtistDetailAlbum extends StatefulWidget {
  const ArtistDetailAlbum({super.key, required this.artist});

  final MixArtist artist;

  @override
  State<ArtistDetailAlbum> createState() => _ArtistDetailAlbumState();
}

class _ArtistDetailAlbumState extends State<ArtistDetailAlbum> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixAlbum> albumList = RxList();

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
      () => PageListView(
        controller: refreshController,
        onRefresh: () {
          return artistSong(artist: widget.artist);
        },
        onLoad: () {
          return artistSong(artist: widget.artist, page: pageEntity.value?.page ?? 0);
        },
        scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
        itemCount: albumList.length,
        itemBuilder: (BuildContext context, int index) {
          var item = albumList[index];
          return ListTile(
            leading: Hero(tag: "${item.package}${item.id}${item.pic}", child: AppImage(url: item.pic ?? "")),
            title: Text("${item.title}", maxLines: 1),
            subtitle: Text("${item.subTitle}", maxLines: 1),
            onTap: () {
              Get.toNamed(Routes.albumDetail, arguments: item);
            },
          );
        },
      ),
    );
  }

  ///获取歌单
  void artistSong({required MixArtist artist, int page = 0}) {
    ApiFactory.api(package: widget.artist.package)?.artistAlbum(artist: artist, page: page, size: 20).then((value) {
      pageEntity.value = value.page;
      if (page == 0) {
        albumList.clear();
        refreshController.finishRefresh();
      }
      refreshController.finishLoad((pageEntity.value?.last != null && pageEntity.value?.last == true) ? IndicatorResult.noMore : IndicatorResult.success, true);

      if (pageEntity.value != null) {
        albumList.addAll(value.data ?? []);
      }
      // showComplete("操作成功");
    }).catchError((e) {
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
