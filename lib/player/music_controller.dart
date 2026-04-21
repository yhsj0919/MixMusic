import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_lrc.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/page/app_music_history/app_history_music_controller.dart';
import 'package:mix_music/page/timer/timer_close_controller.dart';
import 'package:mix_music/player/Player.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/utils/DebounceHelper.dart';
import 'package:mix_music/utils/db.dart';

import '../widgets/message.dart';

class MusicController extends GetxController {
  Rx<Duration> duration = Rx(Duration());
  Rx<Duration> position = Rx(Duration());
  Rxn<MediaItem> media = Rxn();
  Rxn<MixPlayState> state = Rxn();
  Rxn<MixSong> currentMusic = Rxn();
  Rxn<MixLrc> currentLrc = Rxn();
  Rx<bool> isPlaying = Rx(false);

  //播放模式
  Rx<PlayMode> playMode = Rx(PlayMode.RepeatAll);

  // var appC = Get.put(AppController());
  Rxn<MixLrc> lyric = Rxn();
  final LyricController lyricController = LyricController();

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

  AppHistoryMusicController history = Get.put(AppHistoryMusicController());

  DebounceHelper debounceHelper = DebounceHelper();

  @override
  void onInit() {
    super.onInit();
    lyricController.setOnTapLineCallback((Duration position) {
      seek(position);
    });
    currentMusic.value = AppDB.getObject<MixSong>(Constant.KEY_APP_CURRENT_MUSIC);

    AppDB.getList<MixSong>(Constant.KEY_APP_MUSIC_LIST).then((v) {
      musicList.addAll(v);
    });

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
      if ((event?.inMilliseconds ?? 0) >= (duration.value.inMilliseconds - 500)) {
        position.value = duration.value;
        // print('这里改变了播放状态false');
        // isPlaying.value = false;

        if ((duration.value.inMilliseconds > 1000 && position.value.inMilliseconds >= duration.value.inMilliseconds - 500)) {
          debounceHelper.debounce(() {
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
          }, duration: Duration(milliseconds: 300));
        }
      } else {
        // isPlaying.value = true;
        position.value = event ?? Duration();
      }
      lyricController.setProgress(position.value);
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
    AppDB.replaceAll(table: Constant.KEY_APP_MUSIC_LIST, docs: list.map((e) => JsonMapper.toMap(e)!).toList());

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

    requestTimeOut();

    currentMusic.value = music;
    theme.getColorScheme(music.pic);

    musicIndex.value = musicList.indexWhere((element) => element.id.toString() == music.id.toString() && element.package == music.package);
    Player.stop();
    requestFuture?.cancel();

    var playQuality = AppDB.getInt(Constant.KEY_PLAY_QUALITY) ?? 128;
    music.playQuality = playQuality;
    requestFuture = ApiFactory.playUrl(song: music).asStream().listen(
      (value) {
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

        if (media.value?.id.toString() != value.mediaItem().id.toString() && value.getUrl() != null && value.getUrl() != "") {
          if ((value.getLyric()?.lrc?.length ?? 0) > 50) {
            lyricController.loadLyric(
              value.getLyric()?.lrc?.replaceAll(":00]", ".00]") ?? "",
            );
          } else {
            lyric.value = null;
            lyricController.loadLyric('[00:00.00]暂无歌词');
          }
          // if (music.match == true) {
          //   showComplete('音频来自:${ApiFactory.getPlugin(value.matchSong?.package)?.name ?? "未知"}');
          // }
          Player.playMediaItem(music.mediaItem())
              .then((v) {
                AppDB.setObject(Constant.KEY_APP_CURRENT_MUSIC, music);
                history.addHistory(music);
              })
              .catchError((e) {
                print(e);
                media.value = null;
                showError("播放失败");
              });
        } else {
          showError('${music.title} 播放异常，可能无版权');
          Player.stop();
          media.value = null;
          requestFuture?.cancel();
          requestTimeOutFuture?.cancel();
          state.value = null;
          isPlaying.value = false;
          // showError('${music.title} 异常无法播放,尝试下一首');
          // if (musicIndex.value < musicList.length - 1) {
          //   if (isNext) {
          //     next(loop: false);
          //   } else {
          //     previous(loop: false);
          //   }
          // }
        }
      },
      onError: (e) {
        lyricController.loadLyric('[00:00.00]暂无歌词');
        lyric.value = null;
        duration.value = Duration();
        position.value = Duration();
        media.value = null;
        requestTimeOutFuture?.cancel();
        state.value = null;
        isPlaying.value = false;
        Player.stop();
        print(e);
        showError('${music.title} 获取地址失败:$e');
      },
    );
  }

  ///播放音乐
  void playWithQuality({required MixSong music}) {
    requestTimeOutFuture?.cancel();

    state.value = MixPlayState.loading;

    requestTimeOut();

    requestFuture?.cancel();

    requestFuture = ApiFactory.playUrl(song: music, useMatch: false).asStream().listen(
      (value) {
        state.value = MixPlayState.buffering;
        requestTimeOutFuture?.cancel();

        music.url = value.url;
        music.lyric = value.lyric;
        music.quality = value.quality;
        music.playQuality = value.playQuality;

        if (value.getUrl() != null && value.getUrl() != "") {
          currentMusic.update((old) {
            old = music;
          });

          if ((value.getLyric()?.lrc?.length ?? 0) > 50) {
            lyricController.loadLyric(
              value.getLyric()?.lrc?.replaceAll(":00]", ".00]") ?? "",
            );
          } else {
            lyric.value = null;
            lyricController.loadLyric('[00:00.00]暂无歌词');
          }
          Player.pause();
          Player.playWithQualityChange(music.mediaItem(), position.value)
              .then((value) {
                print('>>>>>>>>>这里失败>>>>>>>>>');
              })
              .catchError((e) {
                requestTimeOutFuture?.cancel();
                state.value = null;
                isPlaying.value = false;
                media.value = null;
                showError("播放失败");
              });
        } else {
          showError('${music.title} 播放异常，可能无版权');
          // Player.stop();
          // media.value = null;
          requestFuture?.cancel();
          requestTimeOutFuture?.cancel();
          state.value = null;
          isPlaying.value = false;
          currentMusic.refresh();
        }
      },
      onError: (e) {
        requestTimeOutFuture?.cancel();
        state.value = null;
        isPlaying.value = false;
        print(e);
        showError('${music.title} 获取地址失败:$e');
      },
    );
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
    //  Get.toNamed(id: Routes.key,Routes.playing);
  }

  @override
  void onClose() {
    Player.pause();
    Player.stop();
    Player.dispose();
    lyricController.dispose();
    requestTimeOutFuture?.cancel();
    requestFuture?.cancel();

    super.onClose();
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
