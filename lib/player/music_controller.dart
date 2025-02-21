import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/timer/timer_close_controller.dart';
import 'package:mix_music/player/Player.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/utils/sp.dart';

import '../widgets/message.dart';

class MusicController extends GetxController {
  Rx<Duration> duration = Rx(Duration());
  Rx<Duration> position = Rx(Duration());
  Rxn<MediaItem> media = Rxn();
  Rxn<MixPlayState> state = Rxn();
  Rxn<MixSong> currentMusic = Rxn();
  Rx<bool> isPlaying = Rx(false);

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

  StreamSubscription<dynamic>? requestTimeOutFuture;
  StreamSubscription<dynamic>? requestFuture;
  bool playTimeout = false;

  //倒计时关闭
  TimeCloseController timeClose = Get.put(TimeCloseController());

  @override
  void onInit() {
    super.onInit();
    currentMusic.value = Sp.getObject<MixSong>(Constant.KEY_APP_CURRENT_MUSIC);

    musicList.addAll(Sp.getList<MixSong>(Constant.KEY_APP_MUSIC_LIST) ?? []);

    musicIndex.value = musicList.indexWhere((element) => element.id.toString() == currentMusic.value?.id.toString() && element.package == currentMusic.value?.package);

    Player.media.listen((event) {
      media.value = event;
    });

    Player.playingStream.listen((playing) {
      print('>>>>播放状态${playing}>>>>>>');
      isPlaying.value = playing;
    });

    Player.processingStateStream.listen((s) {
      print('>>>>状态${s}>>>>>>');
      if (s == ProcessingState.loading) {
        state.value = MixPlayState.loading;
      } else if (s == ProcessingState.buffering) {
        state.value = MixPlayState.buffering;
      } else if (s == ProcessingState.completed) {
        isPlaying.value = false;
        state.value = MixPlayState.completed;
      } else if (s == ProcessingState.ready) {
        state.value = MixPlayState.ready;
      }
    });

    Player.durationStream.listen((event) {
      duration.value = event ?? Duration();
    });
    Player.positionStream.listen((event) {
      if ((event?.inMilliseconds ?? 0) >= (duration.value.inMilliseconds ?? 1)) {
        position.value = duration.value;
        // print('这里改变了播放状态false');
        // isPlaying.value = false;

        if ((duration.value.inMilliseconds > 1000 && duration.value.inMilliseconds == position.value.inMilliseconds)) {
          if (timeClose.shouldClose.value && timeClose.stopWithTimer.value) {
            isPlaying.value = false;
            duration.value = Duration();
            position.value = Duration();
            print('这里触发定时停止');
            Player.pause();
            seek(Duration());
            timeClose.stopCountdown();
          } else {
            print('这里触发下一首了');
            if (playMode.value == PlayMode.RepeatOne) {
              isPlaying.value = false;
              playOrPause();
            }
            if (playMode.value == PlayMode.RepeatAll) {
              if (musicList.length == 1) {
                playOrPause();
              } else {
                next(loop: false);
              }
            }
          }
        }
      } else {
        // isPlaying.value = true;
        position.value = event ?? Duration();
      }
    });

    Player.onNext.listen((event) {
      print('下一首');
      next();
    });
    //
    Player.onPrevious.listen((event) {
      print('上一首');
      previous();
    });
  }

  ///播放音乐
  void playList({required List<MixSong> list, int index = 0}) {
    musicList.clear();
    musicList.addAll(list);
    musicIndex.value = index;
    var music = list[index];
    Sp.setList(Constant.KEY_APP_MUSIC_LIST, list);

    play(music: music);
  }

  ///播放音乐
  void play({required MixSong music}) {
    if (music.id == currentMusic.value?.id && music.package == currentMusic.value?.package && isPlaying.value) {
      print('同一首歌，不进行其他操作');
      return;
    }
    requestTimeOutFuture?.cancel();

    // if (state.value == MixPlayState.loading || state.value == MixPlayState.buffering || !isPlaying.value) {
    //   showInfo('正在加载，稍等吧');
    //   return;
    // }
    state.value = MixPlayState.loading;

    Sp.setObject(Constant.KEY_APP_CURRENT_MUSIC, music);
    Sp.insertList(Constant.KEY_APP_HISTORY_MUSIC_LIST, music, index: 0, check: (oldValue, newValue) {
      return oldValue.package == newValue.package && oldValue.id.toString() == newValue.id.toString();
    });

    requestTimeOut();

    currentMusic.value = music;
    theme.getColorScheme(music.pic);

    musicIndex.value = musicList.indexWhere((element) => element.id.toString() == music.id.toString() && element.package == music.package);
    Player.stop();
    requestFuture?.cancel();

    var playQuality = Sp.getInt(Constant.KEY_PLAY_QUALITY) ?? 128;
    music.playQuality = playQuality;
    requestFuture = ApiFactory.playUrl(package: music.package, song: music).asStream().listen((value) {
      state.value = MixPlayState.buffering;
      requestTimeOutFuture?.cancel();
      musicIndex.value = musicList.indexWhere((element) => element.id.toString() == music.id.toString() && element.package == music.package);

      music.url = value.url;
      music.lyric = value.lyric;
      music.match = value.match;
      music.matchSong = value.matchSong;
      music.quality = value.quality;
      music.playQuality = value.playQuality;

      currentMusic.update((old) {
        old = music;
      });

      if (media.value?.id != value.mediaItem().id && value.getUrl() != null && value.getUrl() != "") {
        if ((value.getLyric()?.length ?? 0) > 50) {
          lyricModel.value = LyricsModelBuilder.create().bindLyricToMain(value.getLyric()?.replaceAll(":00]", ".00]") ?? "").getModel();
        } else {
          lyric.value = "暂无歌词";
          lyricModel.value = LyricsModelBuilder.create().bindLyricToMain("暂无歌词").getModel();
        }
        // if (music.match == true) {
        //   showComplete('音频来自:${ApiFactory.getPlugin(value.matchSong?.package)?.name ?? "未知"}');
        // }
        Player.playMediaItem(music.mediaItem()).then((value) {}).catchError((e) {
          print(e);
          media.value = null;
          showError("播放失败");
        });
      } else {
        showError('${music.title} 异常无法播放');
        // showError('${music.title} 异常无法播放,尝试下一首');
        // if (musicIndex.value < musicList.length - 1) {
        //   if (isNext) {
        //     next(loop: false);
        //   } else {
        //     previous(loop: false);
        //   }
        // }
      }
    }, onError: (e) {
      requestTimeOutFuture?.cancel();
      state.value = null;
      isPlaying.value = false;
      Player.stop();
      print(e);
      showError('${music.title} 获取地址失败:$e');
    });
  }

  void requestTimeOut() {
    playTimeout = false;
    requestTimeOutFuture = Future.delayed(const Duration(seconds: 15)).asStream().listen((value) {
      state.value = null;
      isPlaying.value = false;
      requestTimeOutFuture?.cancel();
      requestFuture?.cancel();
      Player.stop();
      playTimeout = true;
      showError('请求超时');
    });
  }

  ///播放音乐
  void playOrPause() {
    if (playTimeout) {
      play(music: currentMusic.value!);
    } else if (isPlaying.value) {
      Player.pause();
    } else {
      if (state.value == null) {
        if (media.value != null) {
          Player.playMediaItem(media.value!);
        } else {
          if (currentMusic.value != null) {
            play(music: currentMusic.value!);
          }
        }
      } else {
        if (state.value == MixPlayState.completed || (duration.value.inMilliseconds > 0 && duration.value == position.value)) {
          Player.seek(Duration.zero);
          isPlaying.value = Player.isPlaying();
        } else {
          Player.resume();
        }
      }
    }
  }

  void stop() {
    Player.stop();
  }

  void pause() {
    if (isPlaying.value) {
      Player.pause();
    }
  }

  ///跳转
  Future<void> seek(Duration position) async {
    isPlaying.value = Player.isPlaying();

    Player.seek(position);
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
        seek(Duration());
        Player.pause();
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
        seek(Duration());
        Player.pause();
        showInfo("已经是最后一首了");
      }
    }
  }

  void jump() {
    // appC.showPlayerBar.value = false;
    // Get.toNamed(Routes.playing);
  }

  @override
  void onClose() {
    super.onClose();
    requestTimeOutFuture?.cancel();
    requestFuture?.cancel();
    Player.dispose();
  }
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
