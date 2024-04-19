import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/message.dart';

import '../../widgets/page_list_view.dart';

class SearchTabPage extends StatefulWidget {
  const SearchTabPage({super.key, required this.plugin, required this.keyWord});

  final PluginsInfo plugin;
  final String keyWord;

  @override
  State<SearchTabPage> createState() => _SearchTabPageState();
}

class _SearchTabPageState extends State<SearchTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  ApiController api = Get.put(ApiController());
  MusicController music = Get.put(MusicController());

  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixSong> songList = RxList();

  @override
  void initState() {
    super.initState();
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    if (widget.keyWord.isNotEmpty) {
      searchSong(keyword: widget.keyWord);
    }
    print("${widget.plugin.name}>>>${widget.keyWord}");
  }

  @override
  void didUpdateWidget(covariant SearchTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyWord != oldWidget.keyWord && widget.keyWord.isNotEmpty) {
      searchSong(keyword: widget.keyWord);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () => PageListView(
        controller: refreshController,
        onRefresh: () {
          return searchSong(keyword: widget.keyWord);
        },
        onLoad: () {
          return searchSong(keyword: widget.keyWord, page: pageEntity.value?.page ?? 0);
        },
        scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
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
                subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
                onTap: () {
                  music.playList(list: songList, index: index);
                },
              ));
        },
      ),
    );
  }

  Future<void> searchSong({required String keyword, int page = 0, int size = 20}) {
    if (keyword.isEmpty) {
      return Future(() => null);
    }
    return api.searchSong(site: widget.plugin.site!, keyword: keyword, page: page, size: size).then((value) {
      pageEntity.value = value.page;
      if (page == 0) {
        songList.clear();
        refreshController.finishRefresh();
      }
      refreshController.finishLoad((pageEntity.value?.last != null && pageEntity.value?.last == true) ? IndicatorResult.noMore : IndicatorResult.success, true);

      songList.addAll(value.data ?? []);
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

  @override
  bool get wantKeepAlive => true;
}
