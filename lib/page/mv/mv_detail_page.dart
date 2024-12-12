import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../entity/page_entity.dart';
import '../../player/music_controller.dart';
import '../../widgets/message.dart';

class MvDetailPage extends StatefulWidget {
  const MvDetailPage({super.key});

  @override
  State<MvDetailPage> createState() => _MvDetailPageState();
}

class _MvDetailPageState extends State<MvDetailPage> {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());
  Rxn<MixMv> mv = Rxn();

  final RxBool _isVisible = RxBool(false);

  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _isVisible.value = true;
    });

    mv.value = Get.arguments;

    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      getAlbumInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      floatingActionButton: PlayBar(),
      body: PageCustomScrollView(
        controller: refreshController,
        onRefresh: () {
          return getAlbumInfo();
        },
        slivers: [
          HyperAppbar(title: mv.value?.title ?? ""),
        ],
      ),
    );
  }

  ///获取专辑
  void getAlbumInfo({int page = 0}) {
    ApiFactory.api(package: mv.value?.package ?? "")?.mvInfo(mv: mv.value!, page: page, size: 20).then((value) {
      firstLoad.value = false;

      if (page == 0) {
        mv.value = value.data;
        refreshController.finishRefresh();
      }
      refreshController.finishLoad(IndicatorResult.noMore, true);

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
