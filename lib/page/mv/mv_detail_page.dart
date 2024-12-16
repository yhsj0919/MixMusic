import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';
import 'package:universal_video_controls/universal_video_controls.dart';
import 'package:universal_video_controls_video_player/universal_video_controls_video_player.dart';
import 'package:video_player/video_player.dart';

import '../../player/music_controller.dart';
import '../../widgets/message.dart';
import 'package:universal_video_controls/universal_video_controls.dart';
import 'package:video_player/video_player.dart';

class MvDetailPage extends StatefulWidget {
  const MvDetailPage({super.key});

  @override
  State<MvDetailPage> createState() => _MvDetailPageState();
}

class _MvDetailPageState extends State<MvDetailPage> with WidgetsBindingObserver {
  MusicController music = Get.put(MusicController());
  Rxn<MixMv> mv = Rxn();

  RxBool firstLoad = RxBool(true);

  late VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 注册生命周期观察者
    WidgetsBinding.instance.addObserver(this);

    mv.value = Get.arguments;
    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      getAlbumInfo();
    });
  }

  void _initializeVideoPlayer(String source) async {
    _controller = VideoPlayerController.network(source);
    await _controller?.initialize();
    setState(() {
      _isInitialized = true;
    });
    _controller?.play();
    _controller?.addListener(() {
      if (_controller?.value.hasError == true) {
        debugPrint(_controller?.value.errorDescription);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 12,
              child: _isInitialized
                  ? VideoControls(
                      player: VideoPlayerControlsWrapper(_controller!),
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: const CircularProgressIndicator(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 监听应用是否从后台切换到前台
    if (state == AppLifecycleState.resumed) {
      // 应用返回前台时，恢复视频播放
      if (_controller?.value.isInitialized == true && _controller?.value.isPlaying != true) {
        _controller?.play();
      }
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台时，暂停视频播放
      if (_controller?.value.isInitialized == true && _controller?.value.isPlaying == true) {
        _controller?.pause();
      }
    }
  }

  ///获取专辑
  void getAlbumInfo() {
    ApiFactory.api(package: mv.value?.package ?? "")?.mvInfo(mv: mv.value!, page: 0, size: 20).then((value) {
      firstLoad.value = false;

      mv.value = value.data;

      _initializeVideoPlayer(mv.value?.url ?? "");
      // showComplete("操作成功");
    }).catchError((e) {
      firstLoad.value = false;
      print(e);

      showError(e);
    });
  }
}
