import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/player/Player.dart';
import 'package:mix_music/theme/theme_controller.dart';

import '../widgets/message.dart';

class MusicController extends GetxController {
  Rxn<Duration> duration = Rxn();
  Rxn<Duration> position = Rxn();
  Rxn<MediaItem> media = Rxn();
  Rxn<MixSong> currentMusic = Rxn();
  Rxn<PlayerState> state = Rxn();
  Rx<bool> isBuffering = Rx(false);

  //播放模式
  Rx<PlayMode> playMode = Rx(PlayMode.RepeatAll);

  // var appC = Get.put(AppController());
  Rxn<LyricsReaderModel> lyricModel = Rxn();
  RxString lyric = RxString("暂无歌词");

  RxInt musicIndex = RxInt(-1);
  RxList<MixSong> musicList = RxList();

  //这个用于解决跳转上一首歌，结果上一首歌无法播放的问题
  bool isNext = true;

  ThemeController theme = Get.put(ThemeController());

  @override
  void onInit() {
    super.onInit();
    Player.onNext.listen((event) {
      print('下一首');
      next();
    });
    //
    Player.onPrevious.listen((event) {
      print('上一首');
      previous();
    });

    Player.media.listen((event) {
      media.value = event;
    });

    Player.onPlayerComplete.listen((event) {
      duration.value = Duration();
      position.value = Duration();
      // playOrPause();
      if (playMode.value == PlayMode.RepeatOne) {
        playOrPause();
      }
      if (playMode.value == PlayMode.RepeatAll) {
        if (musicList.length == 1) {
          playOrPause();
        } else {
          next(loop: false);
        }
      }
    });
    Player.onDurationChanged.listen((event) {
      duration.value = event;
    });
    Player.onPositionChanged.listen((event) {
      if (event.inMilliseconds >= (duration.value?.inMilliseconds ?? 1)) {
        position.value = duration.value;
      } else {
        position.value = event;
      }
    });

    Player.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.playing) {
        isBuffering.value = false;
      }
      state.value = event;
    });
  }

  ///播放音乐
  void playList({required List<MixSong> list, int index = 0}) {
    musicList.clear();
    musicList.addAll(list);
    musicIndex.value = index;
    var music = list[index];
    play(music: music);
  }

  ///播放音乐
  void play({required MixSong music}) {
    if (music.id == currentMusic.value?.id && music.package == currentMusic.value?.package && Player.state == PlayerState.playing) {
      print('同一首歌，不进行其他操作');
      return;
    }

    if (isBuffering.value) {
      showInfo('正在加载，稍等吧');
      return;
    }

    isBuffering.value = true;
    currentMusic.value = music;
    theme.getColorScheme(music.pic);

    musicIndex.value = musicList.indexWhere((element) => element.id == music.id && element.package == music.package);
    Player.stop();
    ApiFactory.playUrl(package: music.package, song: music).then((value) {
      musicIndex.value = musicList.indexWhere((element) => element.id == music.id && element.package == music.package);
      music.url = value.url;
      music.lyric = value.lyric;
      currentMusic.value = music;
      if (media.value?.id != value.mediaItem().id && value.url != null && value.url != "") {
        if ((value.lyric?.length ?? 0) > 50) {
          lyricModel.value = LyricsModelBuilder.create().bindLyricToMain(value.lyric?.replaceAll(":00]", ".00]") ?? "").getModel();
        } else {
          lyric.value = "暂无歌词";
          lyricModel.value = LyricsModelBuilder.create().bindLyricToMain("暂无歌词").getModel();
        }
        if (music.package != value.package) {
          showComplete('音频来自:${ApiFactory.getPlugin(value.package)?.name ?? "未知"}');
        }
        isBuffering.value = true;
        Player.playMediaItem(music.mediaItem()).then((value) {
          isBuffering.value = false;
        }).catchError((e) {
          print(e);
          isBuffering.value = false;
          media.value = null;
          showError("播放失败");
        });
      } else {
        isBuffering.value = false;
        showError('${music.title} 异常无法播放,尝试下一首');
        if (musicIndex.value < musicList.length - 1) {
          if (isNext) {
            next(loop: false);
          } else {
            previous(loop: false);
          }
        }
      }
    }).catchError((e) {
      isBuffering.value = false;
      print(e);
      showError('${music.title} 获取地址失败:$e');
    });
  }

  ///播放音乐
  void playOrPause() {
    if (Player.state == PlayerState.playing) {
      Player.pause();
    } else if (Player.state == PlayerState.paused) {
      Player.resume();
    } else {
      if (media.value != null) {
        Player.playMediaItem(media.value!);
      }
    }
  }

  ///跳转
  Future<void> seek(Duration position) async {
    return Player.seek(position);
  }

  ///跳转
  void previous({bool loop = true}) async {
    isNext = false;
    if (musicIndex.value > 0) {
      musicIndex.value--;
      play(music: musicList[musicIndex.value]);
    } else {
      if (loop) {
        musicIndex.value = musicList.length - 1;
        play(music: musicList[musicIndex.value]);
      } else {
        showInfo("已经是第一首了");
      }
    }
  }

  void next({bool loop = true}) async {
    isNext = true;
    if (musicIndex.value < musicList.length - 1) {
      musicIndex.value++;
      play(music: musicList[musicIndex.value]);
    } else {
      if (loop) {
        musicIndex.value = 0;
        play(music: musicList[musicIndex.value]);
      } else {
        showInfo("已经是最后一首了");
      }
    }
  }

  void jump() {
    // appC.showPlayerBar.value = false;
    // Get.toNamed(Routes.playing);
  }

  void setPlayMode(PlayerMode mode) {}
}

enum PlayMode {
  ///单曲循环
  RepeatOne,

  ///全部循环
  RepeatAll,

  ///随机播放
  // Shuffle,

  ///顺序播放
  // Sequential,
}
