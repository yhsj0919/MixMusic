import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mix_music/widgets/message.dart';

import 'AudioPlayerHandler.dart';

class Player {
  static late AudioHandler _audioHandler;
  static late AudioSession _session;

  static final AudioPlayer _player = AudioPlayer();

  static Stream<MediaItem> get media => _mediaController.stream;

  static final StreamController<MediaItem> _mediaController = StreamController<MediaItem>();

  ///进度修改
  static Stream<Duration> get onPositionChanged => _player.onPositionChanged.asBroadcastStream();

  ///歌曲时间
  static Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  ///播放状态
  static Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  ///播放完成
  static Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  static Stream<void> get eventStream => _player.eventStream;

  ///进度条拖动后的回调
  static Stream<void> get onSeekComplete => _player.onSeekComplete;

  ///状态
  static PlayerState get state => _player.state;

  static Stream<AudioInterruptionEvent> get interruptionEventStream => _session.interruptionEventStream;

  ///
  static Stream<Set<AudioDevice>> get devicesStream => _session.devicesStream;

  ///拔下耳机
  static Stream<void> get becomingNoisyEventStream => _session.becomingNoisyEventStream;

  ///设备更改
  static Stream<AudioDevicesChangedEvent> get devicesChangedEventStream => _session.devicesChangedEventStream;

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

  ///初始化控件
  static Future<void> init() async {
    _session = await AudioSession.instance;
    await _session.configure(const AudioSessionConfiguration.music());
    // await _session.setActive(true);
    print('>>>>_session初始化>>>>>>>>');
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
  }

  ///播放音乐
  static Future<void> playMediaItem(MediaItem mediaItem) {
    _mediaController.add(mediaItem);

    return _audioHandler.playMediaItem(mediaItem);
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
    if (_player.source != null) {
      return _player.resume();
    } else {
      return Future(() => null);
    }
  }

  ///播放器播放
  static Future<void> play(Source source, {double? volume, double? balance, AudioContext? ctx, Duration? position, PlayerMode? mode}) async {
    return _player.play(source, volume: volume, balance: balance, ctx: ctx, position: position, mode: mode);
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
}
