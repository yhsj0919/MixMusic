import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:smtc_windows/smtc_windows.dart';

import 'just_audio_background.dart';

class Player {
  static late AudioSession _session;

  static final AudioPlayer _player = AudioPlayer();

  static Stream<MediaItem> get media => _mediaController.stream;

  static final StreamController<MediaItem> _mediaController = StreamController<MediaItem>();

  static Stream<Duration?> get durationStream => _player.durationStream;

  static Stream<Duration?> get positionStream => _player.positionStream;

  static Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  static Stream<bool> get playingStream => _player.playingStream;

  ///下一首
  static Stream<void> get onNext => _onNext.stream;
  static StreamController<void>? __onNext;

  static StreamController<void> get _onNext {
    return __onNext ??= StreamController<void>();
  }

  ///上一首
  static Stream<void> get onPrevious => _onPrevious.stream;
  static StreamController<void>? __onPrevious;

  static StreamController<void> get _onPrevious {
    return __onPrevious ??= StreamController<void>();
  }

  static bool isPlaying() {
    return _player.playing;
  }

  static bool isLoading() {
    return _player.playerState.processingState == ProcessingState.loading || _player.playerState.processingState == ProcessingState.buffering;
  }

  static bool completed() {
    return _player.playerState.processingState == ProcessingState.completed;
  }

  static ProcessingState processingState() {
    return _player.playerState.processingState;
  }

  ///初始化控件
  static Future<void> init() async {
    _session = await AudioSession.instance;
    await _session.configure(const AudioSessionConfiguration.music());
    // await _session.setActive(true);
    print('>>>>_session初始化>>>>>>>>');
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
  }

  ///播放音乐
  static Future<void> playMediaItem(MediaItem mediaItem) async {
    _mediaController.add(mediaItem);
    print('这是ID${mediaItem.extras?["id"]}');

    // LockCachingAudioSource(Uri.parse(mediaItem.id), tag: mediaItem);

    var media = AudioSource.uri(
      Uri.parse(mediaItem.id),
      tag: mediaItem,
    );
    try {
      await _player.setAudioSource(media);
    } catch (e, stackTrace) {
      print("Error loading playlist: $e");
      print(stackTrace);
    }

    return _player.play();
  }

  ///停止
  static void stop() {
    _player.stop();
  }

  ///暂停
  static void pause() {
    _player.pause();
  }

  ///恢复播放
  static Future<void> resume() async {
    if (_player.audioSource != null) {
      return _player.play();
    } else {
      return Future(() => null);
    }
  }

  ///恢复播放
  static Future<void> play() async {
    return _player.play();
  }

  ///跳转
  static Future<void> seek(Duration position) async {
    return _player.seek(position);
  }

  ///下一首
  static Future<void> next() async {
    _onNext.add(null);
  }

  ///上一首
  static Future<void> previous() async {
    _onPrevious.add(null);
  }

  //设置音量
  static Future<void> setVolume(double volume) async {
    return _player.setVolume(volume);
  }

  //获取音量
  static double getVolume() {
    return _player.volume;
  }

  static Future<bool> setActive(bool active) {
    return _session.setActive(active);
  }

  static AudioSession getSession() {
    return _session;
  }

  static void dispose() {
    _player.stop();
    _player.dispose();
  }
}

enum MixPlayState {
  ///没有任何数据
  idle,

  ///加载中
  loading,

  ///缓冲
  buffering,

  ///准备好
  ready,

  ///完成
  completed,
}
