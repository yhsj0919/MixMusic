import 'package:lemon_x/lemon_x.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:lemon_audio/lemon_audio.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' as mpv;
import 'package:shared_preferences/shared_preferences.dart';

import '../entity/quality.dart';

import '../plugin/plugin_controller.dart';
import 'player_lyric.dart';
import 'sleep_timer.dart';
import 'equalizer_controller.dart';
import 'player_session.dart';
import 'music_cache.dart';
import '../queue/hyper_queue.dart';
import '../queue/hyper_queue_source.dart';
import '../entity/song.dart';
import '../plugin/collection_controller.dart';
import '../plugin/song_matcher.dart';

enum PlayMode {
  sequence('顺序播放'),
  loop('列表循环'),
  single('单曲循环'),
  shuffle('随机播放');

  const PlayMode(this.title);
  final String title;
}

class PlayerController extends LxController {
  PlayerController(this.plugins, {MusicCache? cache, this.preferences}) {
    lyrics = own(PlayerLyric(this));
    sleepTimer = own(SleepTimer(this));
    equalizer = own(EqualizerController(this));
    this.cache = own(
      cache ??
          MusicCache(
            preferences: preferences,
            onLog: (message) => plugins.addLog('cache', 'log', message),
          ),
    );
    hyperQueue.items.addListener(syncQueue);
    mode.addListener(() => preferences?.setString('playMode', mode.value.name));
    session = own(PlayerSession(this));
  }
  late final PlayerSession session;
  late final PlayerLyric lyrics;
  late final SleepTimer sleepTimer;
  late final EqualizerController equalizer;
  late final MusicCache cache;
  final PluginController plugins;
  final SharedPreferences? preferences;
  late final allowConcurrentPlayback = own(
    (preferences?.getBool('allowConcurrentPlayback') ?? false).obs,
  );
  late final titleLyrics = own(
    (preferences?.getBool('titleLyrics') ?? false).obs,
  );

  Future<void> setAllowConcurrentPlayback(bool value) async {
    allowConcurrentPlayback.value = value;
    await preferences?.setBool('allowConcurrentPlayback', value);
    try {
      await audio?.setAllowConcurrentPlayback(value);
    } catch (error, stack) {
      reportControlError('同时播放设置失败', error, stack);
    }
  }

  Future<void> setTitleLyrics(bool value) async {
    titleLyrics.value = value;
    await preferences?.setBool('titleLyrics', value);
    await lyrics.syncTitle(force: true);
  }

  Future<void> updateMediaLyric(String? text) async {
    try {
      await audio?.updateLyric(text, mode: LemonLyricMode.bluetoothTitle);
    } catch (error, stack) {
      reportControlError('标题歌词同步失败', error, stack);
    }
  }

  late final defaultQuality = own(
    (preferences?.getInt('playQuality') ?? 128).obs,
  );

  Future<void> setDefaultQuality(int value) async {
    defaultQuality.value = value;
    await preferences?.setInt('playQuality', value);
  }

  late final song = own(Rx<Song?>(null));
  late final playing = own(false.obs);
  late final position = own(Rx(Duration.zero));
  late final duration = own(Rx(Duration.zero));
  late final status = own(''.obs);
  late final lyric = own(Rx<Map<String, dynamic>?>(null));
  late final lyricSource = own(Rx<Song?>(null));
  int _lyricRequest = 0;
  late final hyperQueue = own(
    HyperQueue<Song>(
      same: sameSong,
      snapshot: (item) => Song.fromJson(item.toJson()),
    ),
  );
  Rx<List<Song>> get queue => hyperQueue.items;
  Rx<int> get currentIndex => hyperQueue.index;
  late final mode = own(
    (PlayMode.values.firstWhere(
      (item) => item.name == preferences?.getString('playMode'),
      orElse: () => PlayMode.sequence,
    )).obs,
  );
  late final volume = own((preferences?.getDouble('volume') ?? 1.0).obs);
  late final muted = own((preferences?.getBool('muted') ?? false).obs);
  late final speed = own((preferences?.getDouble('speed') ?? 1.0).obs);
  late final controlError = own(''.obs);
  final _history = <Song>[];
  final _random = Random();

  bool _completed = false;
  Object? _failure;
  bool get _failed => _failure != null;
  bool _loadingTrack = false;
  bool _playWhenReady = true;
  MpvPlayer? engine;
  LemonAudio? audio;
  Future<void>? _initializing;
  int _loadId = 0;

  Future<void> initializeAudio() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    mpv.MpvAudioKit.ensureInitialized();
    final adapter = engine = MpvPlayer(
      onNext: next,
      onPrevious: previous,
      onQueueItem: playAt,
      queueIndex: () => currentIndex.value,
      onPlaybackIntent: (play) => _playWhenReady = play,
      onRetry: play,
    );
    await adapter.player.setSourceResolver(
      resolve,
      timeout: const Duration(seconds: 30),
    );
    own(adapter.stateStream.listen(updateState));
    own(
      adapter.player.stream.metadata.listen((tags) {
        final current = song.value;
        if (current == null || tags.isEmpty) return;
        final updated = plugins
            .music(current.pluginId)
            .updateMetadata(current, tags);
        if (identical(updated, current)) return;
        song.value = updated;
        if (updated.title != current.title ||
            updated.subtitle != current.subtitle) {
          unawaited(loadLyric(updated));
        }
        for (final queued in queue.value) {
          if (sameSong(queued, current)) {
            queued.title = updated.title;
            queued.subtitle = updated.subtitle;
            queued.details = updated.details;
          }
        }
        queue.refresh();
        unawaited(
          audio
                  ?.setTrack(
                    LemonAudioTrack(
                      id: jsonEncode([updated.pluginId, updated.id]),
                      title: updated.title,
                      artist: updated.subtitle,
                      duration: duration.value,
                      artUri: updated.cover == null
                          ? null
                          : Uri.parse(updated.cover!),
                    ),
                  )
                  .then((_) {
                    if (!isDisposed) {
                      audio?.setPosition(position.value);
                      lyrics.syncTitle(force: true);
                    }
                  }) ??
              Future.value(),
        );
      }),
    );
    own(
      adapter.player.stream.duration.listen((value) {
        duration.value = value;
        audio?.setDuration(value);
      }),
    );
    own(
      adapter.player.stream.error.listen((error) {
        if (error is mpv.MpvEndFileError) {
          reportError(error);
        } else {
          plugins.addLog(song.value?.pluginId ?? 'player', 'warn', '$error');
        }
      }),
    );
    audio = await LemonAudio.initialize(
      player: adapter,
      config: LemonAudioConfig(
        androidNotificationChannelId: 'mixmusic.playback',
        androidNotificationChannelName: '音乐播放',
        androidNotificationOngoing: true,
        allowConcurrentPlayback: allowConcurrentPlayback.value,
        resumeAfterInterruption: true,
      ),
    );
    await audio!.setAllowConcurrentPlayback(allowConcurrentPlayback.value);
    await adapter.setUserVolume(volume.value);
    await adapter.setMuted(muted.value);
    await adapter.setSpeed(speed.value);
    await equalizer.apply();
    await audio!.setNotificationButtons([
      LemonNotificationButton.previous,
      LemonNotificationButton.playPause,
      LemonNotificationButton.next,
      LemonNotificationButton.stop,
    ]);
    syncQueue();
  }

  bool sameSong(Song a, Song b) =>
      a.pluginId == b.pluginId &&
      const DeepCollectionEquality().equals(a.id, b.id);

  int addSong(Song selected, {bool next = false, int? quality}) {
    final index = next
        ? hyperQueue.insertNext(selected)
        : hyperQueue.append(selected);
    if (quality != null) {
      hyperQueue.replace(
        index,
        Song.fromJson(queue.value[index].toJson())..playQuality = quality,
      );
    }
    syncQueue();
    return index;
  }

  Future<void> playSong(Song selected, {int? quality}) =>
      playAt(addSong(selected, quality: quality), quality: quality);

  Future<void> addCollection(
    CollectionController collection, {
    bool play = false,
    bool next = false,
  }) async {
    if (play) {
      hyperQueue.clear();
      _history.clear();
    }
    hyperQueue.appendCollection(
      HyperQueueSource<Song>(
        key: collection,
        title: collection.resource.title,
        items: collection.songs,
        hasMore: collection.hasMore,
        error: collection.error,
        loadMore: collection.loadMore,
      ),
      next: next,
    );
    if (play) {
      final index = await hyperQueue.collectionIndex(collection);
      if (!isDisposed && index != null) {
        final current = song.value;
        if (current != null && sameSong(current, queue.value[index])) {
          currentIndex.value = index;
          if (!playing.value) await this.play();
        } else {
          await playAt(index);
        }
      }
    }
    if (!isDisposed) syncQueue();
  }

  Future<void> loadMoreQueue({bool viewing = false, bool retry = false}) =>
      hyperQueue.loadMore(viewing: viewing, retry: retry);

  Future<void> playAt(int index, {int? quality, bool remember = true}) async {
    if (index < 0 || index >= queue.value.length) return;
    if (remember &&
        mode.value == PlayMode.shuffle &&
        currentIndex.value >= 0 &&
        currentIndex.value != index) {
      _history.add(queue.value[currentIndex.value]);
    }
    currentIndex.value = index;
    final selected = Song.fromJson(queue.value[index].toJson());

    selected.playQuality =
        quality ??
        selected.playQuality ??
        Quality.select(selected.qualities, defaultQuality.value);
    await loadSong(selected);
    if (!isDisposed) unawaited(loadMoreQueue());
  }

  Future<void> next({bool completed = false}) async {
    if (completed && sleepTimer.waiting.value) {
      await sleepTimer.stop();
      return;
    }
    if (hyperQueue.entries.value.isEmpty) return;
    if (queue.value.isEmpty) {
      final first = await hyperQueue.nextIndex();
      if (!isDisposed && first != null) await playAt(first);
      return;
    }
    var index = currentIndex.value;
    if (mode.value != PlayMode.shuffle &&
        !(completed && mode.value == PlayMode.single)) {
      final selected = index < 0 ? null : queue.value[index];
      final next = await hyperQueue.nextIndex();
      if (isDisposed ||
          (selected != null &&
              (currentIndex.value < 0 ||
                  queue.value[currentIndex.value] != selected))) {
        return;
      }
      if (hyperQueue.error.value.isNotEmpty) {
        status.value = '加载更多失败：${hyperQueue.error.value}';
        return;
      }
      if (next != null) {
        await playAt(next);
        return;
      }
      if (hyperQueue.hasMore || queue.value.isEmpty) return;
      if (completed && mode.value == PlayMode.sequence) return;
      await playAt(0);
      return;
    }
    if (completed && mode.value == PlayMode.single && index >= 0) {
      await playAt(index);
      return;
    }
    if (mode.value == PlayMode.shuffle &&
        queue.value.length > 1 &&
        index >= 0) {
      final offset = _random.nextInt(queue.value.length - 1) + 1;
      index = (index + offset) % queue.value.length;
    } else {
      index++;
      if (index == queue.value.length) {
        if (completed && mode.value == PlayMode.sequence) return;
        index = 0;
      }
    }
    await playAt(index);
  }

  Future<void> previous() async {
    if (queue.value.isEmpty) return;
    if (mode.value == PlayMode.shuffle && _history.isNotEmpty) {
      final previous = _history.removeLast();
      final index = queue.value.indexWhere((item) => sameSong(item, previous));
      if (index >= 0) {
        await playAt(index, remember: false);
        return;
      }
    }
    await playAt(
      currentIndex.value < 0
          ? 0
          : (currentIndex.value - 1 + queue.value.length) % queue.value.length,
    );
  }

  void cycleMode() {
    mode.value =
        PlayMode.values[(mode.value.index + 1) % PlayMode.values.length];
    _history.clear();
  }

  Future<void> removeSong(int index) async {
    final removed = queue.value[index];
    final wasCurrent = currentIndex.value == index;
    hyperQueue.remove(index);
    _history.removeWhere((item) => sameSong(item, removed));
    syncQueue();
    if (queue.value.isEmpty && !hyperQueue.hasMore) {
      await clearQueue();
    } else if (wasCurrent) {
      currentIndex.value = min(index - 1, queue.value.length - 1);
      final following = await hyperQueue.nextIndex();
      if (isDisposed) return;
      if (hyperQueue.error.value.isNotEmpty) {
        status.value = '加载更多失败：${hyperQueue.error.value}';
      } else if (following != null) {
        await playAt(following);
      } else if (queue.value.isNotEmpty) {
        await playAt(min(index, queue.value.length - 1));
      }
    }
  }

  Future<void> clearQueue() async {
    hyperQueue.clear();
    _history.clear();
    syncQueue();
    await stopPlayback();
    await session.save();
  }

  Future<void> removeCollection(Object key) async {
    final current = currentIndex.value;
    hyperQueue.removeCollection(key);
    syncQueue();
    if (current >= 0 && currentIndex.value < 0) {
      if (hyperQueue.entries.value.isEmpty) {
        await stopPlayback();
      } else {
        await next();
      }
    }
  }

  void syncQueue() {
    final output = audio;
    if (output == null) return;
    unawaited(
      output
          .setTracks([
            for (final item in queue.value)
              LemonAudioTrack(
                id: jsonEncode([item.pluginId, item.id]),
                title: item.title,
                artist: item.subtitle,
                artUri: item.cover == null ? null : Uri.parse(item.cover!),
              ),
          ])
          .catchError((Object error, StackTrace stack) {
            plugins.addLog('player', 'warn', '系统队列更新失败：$error\n$stack');
          }),
    );
  }

  void updateState(LemonPlayerState state) {
    if (isDisposed) return;
    playing.value = !_failed && state.playing;
    if (!_failed) position.value = state.position;
    final length = engine?.player.state.duration;
    // 同时长重播可能没有新的 duration 事件，恢复清空或换曲时归零的总时长。
    if (state.processingState == LemonProcessingState.ready &&
        length != null &&
        duration.value != length) {
      duration.value = length;
      audio?.setDuration(length);
    }
    final wasCompleted = _completed;
    _completed = state.processingState == LemonProcessingState.completed;
    if (_completed &&
        !wasCompleted &&
        !_loadingTrack &&
        _playWhenReady &&
        status.value.isEmpty) {
      unawaited(next(completed: true));
    }
  }

  Future<void> loadSong(Song selected) => reloadSong(selected);

  Future<void> switchSource(Song original, Song source) async {
    final current = song.value;
    if (current == null || !SongMatcher.sameSong(current, original)) return;
    final candidate = Song.fromJson(source.toJson())
      ..url = null
      ..playQuality = current.actualSong.playQuality ?? current.playQuality;
    await reloadSong(
      Song.fromJson(current.toJson())..matchedSong = candidate,
      start: position.value,
      play: playing.value,
      keepLyric: true,
    );
  }

  Future<void> reloadSong(
    Song selected, {
    Duration start = Duration.zero,
    bool play = true,
    bool keepLyric = false,
  }) async {
    session.pending = false;
    _failure = null;
    final loadId = ++_loadId;
    _loadingTrack = true;
    _playWhenReady = play;
    song.value = selected;
    position.value = start;
    if (!keepLyric) {
      duration.value = Duration.zero;
      lyric.value = null;
      lyricSource.value = null;
      unawaited(loadLyric(selected));
    }
    status.value = '正在加载';
    try {
      await initializeAudio();
      if (loadId != _loadId || isDisposed) return;
      await audio!.setTrack(
        LemonAudioTrack(
          id: jsonEncode([selected.pluginId, selected.id]),
          title: selected.title,
          artist: selected.subtitle,
          artUri: selected.cover == null ? null : Uri.parse(selected.cover!),
        ),
      );
      await lyrics.syncTitle(force: true);
      if (loadId != _loadId || isDisposed) return;
      await engine!.open(
        mpv.Media(
          selected.url ?? 'mixmusic://track/$loadId',
          extras: {
            'song': selected.toJson(),
            'loadId': loadId,
            'start': start.inMilliseconds,
          },
        ),
      );
      if (loadId != _loadId || isDisposed) return;
      if (_playWhenReady) await audio!.play();
    } catch (error, stack) {
      if (loadId == _loadId) reportError(error, stack);
    } finally {
      if (loadId == _loadId) _loadingTrack = false;
    }
  }

  Future<String?> resolve(mpv.SourceResolveRequest request) async {
    final selected = Song.fromJson(request.media.extras!['song'] as Map);
    try {
      Future<Song> load(Song candidate) => cache.resolve(
        candidate,
        () => plugins.music(candidate.pluginId).playUrl(candidate),
      );
      final resolved = selected.matchedSong != null
          ? await load(selected.actualSong)
          : await plugins.matcher.resolve(
              selected,
              load,
              cancelled: () =>
                  isDisposed || request.media.extras!['loadId'] != _loadId,
            );
      if (request.media.extras!['loadId'] != _loadId || isDisposed) return null;
      cache.activate(resolved);
      if (resolved.url == null || resolved.url!.isEmpty) {
        throw StateError('音源未返回可播放地址');
      }
      final headers = Map<String, String>.from(
        resolved.details['httpHeaders'] as Map? ?? {},
      );
      await engine!.player.setRawProperty(
        'file-local-options/http-header-fields',
        headers.entries
            .map((item) => '${item.key}: ${item.value}'.replaceAll(',', r'\,'))
            .join(','),
      );
      final start = request.media.extras!['start'] as int? ?? 0;
      await engine!.player.setRawProperty(
        'file-local-options/start',
        (start / 1000).toString(),
      );
      if (request.media.extras!['loadId'] == _loadId) {
        song.value = resolved.pluginId == selected.pluginId
            ? resolved
            : (Song.fromJson(selected.toJson())
                ..matchedSong = resolved
                ..playQuality = resolved.playQuality);
        _failure = null;
        engine!.resetFailure();
        status.value = '';
      }
      return resolved.url == request.media.uri
          ? request.uri
          : MpvPlayer.sourceUri(resolved.url!);
    } catch (error, stack) {
      if (request.media.extras!['loadId'] == _loadId && !isDisposed) {
        reportError(error, stack);
      }
      rethrow;
    }
  }

  Future<void> loadLyric(Song selected) async {
    final request = ++_lyricRequest;
    bool cancelled() => isDisposed || request != _lyricRequest;
    try {
      final result = await plugins.lyricMatcher.resolve(
        selected,
        cancelled: cancelled,
      );
      if (cancelled()) return;
      lyricSource.value = result?.source;
      lyric.value = result?.data;
    } catch (error, stack) {
      plugins.addLog(selected.pluginId, 'warn', '歌词获取失败：$error\n$stack');
    }
  }

  Future<void> reloadLyric() async {
    final selected = song.value;
    if (selected != null) await loadLyric(selected);
  }

  Future<bool> switchLyric(Song original, Song source) async {
    final current = song.value;
    if (current == null || !SongMatcher.sameSong(current, original)) {
      return false;
    }
    final request = ++_lyricRequest;
    final result = await plugins.lyricMatcher.load(source);
    if (isDisposed ||
        request != _lyricRequest ||
        result == null ||
        song.value == null ||
        !SongMatcher.sameSong(song.value!, original)) {
      return false;
    }
    lyricSource.value = result.source;
    lyric.value = result.data;
    return true;
  }

  void reportError(Object error, [StackTrace? stack]) {
    // 没有解析出地址时，MPV 的后续加载错误不能覆盖音源失败原因。
    if (error is! mpv.MpvEndFileError || _failure == null) _failure = error;
    final cause = _failure!;
    var message = cause is StateError ? cause.message : '$cause';
    if (message.contains('QuickJS fetch network error:')) {
      message = '网络连接失败，请检查网络后重试';
    } else if (message.contains('QuickJS fetch timed out after')) {
      message = '网络请求超时，请稍后重试';
    }
    status.value = '播放失败：$message';
    playing.value = false;
    engine?.fail(message);
    plugins.addLog(
      song.value?.pluginId ?? 'player',
      'error',
      '$error${stack == null ? '' : '\n$stack'}',
    );
  }

  Future<void> toggle() async {
    if (playing.value && !_failed) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    _playWhenReady = true;
    final current = song.value;
    if (current != null && (session.pending || _failed)) {
      final selected = Song.fromJson(current.toJson())..url = null;
      selected.matchedSong?.url = null;
      if (session.pending) unawaited(loadLyric(selected));
      await reloadSong(selected, start: position.value, keepLyric: true);
      return;
    }
    try {
      await audio?.play();
    } catch (error, stack) {
      if (!isDisposed) reportError(error, stack);
    }
  }

  Future<void> changeQuality(int quality) async {
    final current = song.value;
    if (current == null || current.playQuality == quality) return;
    final selected = Song.fromJson(current.toJson())
      ..playQuality = quality
      ..url = null;
    if (selected.matchedSong != null) {
      selected.matchedSong!
        ..playQuality = quality
        ..url = null;
    }
    await reloadSong(
      selected,
      start: position.value,
      play: playing.value,
      keepLyric: true,
    );
  }

  Future<void> setVolume(double value) async {
    volume.value = value.clamp(0.0, 1.0);
    await preferences?.setDouble('volume', volume.value);
    controlError.value = '';
    try {
      await engine?.setUserVolume(volume.value);
    } catch (error, stack) {
      reportControlError('音量设置失败', error, stack);
    }
  }

  Future<void> setMuted(bool value) async {
    muted.value = value;
    await preferences?.setBool('muted', value);
    controlError.value = '';
    try {
      await engine?.setMuted(value);
    } catch (error, stack) {
      reportControlError('静音设置失败', error, stack);
    }
  }

  Future<void> setSpeed(double value) async {
    speed.value = value.clamp(0.5, 2.0);
    await preferences?.setDouble('speed', speed.value);
    controlError.value = '';
    try {
      await engine?.setSpeed(speed.value);
    } catch (error, stack) {
      reportControlError('倍速设置失败', error, stack);
    }
  }

  void reportControlError(String title, Object error, StackTrace stack) {
    if (isDisposed) return;
    controlError.value = '$title：$error';
    plugins.addLog('player', 'warn', '$title：$error\n$stack');
  }

  Future<void> pause() async {
    _playWhenReady = false;
    try {
      await audio?.pause();
      if (!isDisposed) {
        playing.value = false;
        await session.save();
      }
    } catch (error, stack) {
      if (!isDisposed) reportError(error, stack);
    }
  }

  Future<void> seek(Duration value) async {
    if (session.pending) {
      position.value = duration.value > Duration.zero
          ? Duration(
              milliseconds: value.inMilliseconds.clamp(
                0,
                duration.value.inMilliseconds,
              ),
            )
          : (value < Duration.zero ? Duration.zero : value);
      return;
    }
    try {
      await audio!.seek(value);
    } catch (error, stack) {
      reportError(error, stack);
    }
  }

  Future<void> stopSource(String pluginId) async {
    hyperQueue.removeWhere(
      (item) => item.pluginId == pluginId,
      source: (source) =>
          (source.key as CollectionController).resource.pluginId == pluginId,
    );
    _history.removeWhere((item) => item.pluginId == pluginId);
    syncQueue();
    if (song.value?.pluginId == pluginId) await stopPlayback();
  }

  Future<void> stopPlayback() async {
    _failure = null;
    session.pending = false;
    _lyricRequest++;
    if (sleepTimer.waiting.value) sleepTimer.cancel();
    final loadId = ++_loadId;
    _loadingTrack = true;
    await audio?.stop();
    cache.release();
    if (loadId != _loadId || isDisposed) return;
    _loadingTrack = false;
    song.value = null;
    playing.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    lyric.value = null;
    lyricSource.value = null;
    status.value = '';
  }

  @override
  Future<void> onDispose() async {
    _loadId++;
    if (_initializing != null) {
      try {
        await _initializing;
      } catch (_) {}
    }
    if (audio != null) {
      await audio!.dispose();
    } else {
      await engine?.dispose();
    }
  }
}

class MpvPlayer extends LemonAudioPlayer {
  final Future<void> Function()? onRetry;
  final void Function(bool)? onPlaybackIntent;
  final Future<void> Function()? onNext, onPrevious;
  final Future<void> Function(int)? onQueueItem;
  final int Function()? queueIndex;
  static String sourceUri(String url) {
    if (!url.startsWith('data:')) return url;
    final bytes = Uri.parse(url).data!.contentAsBytes();
    return 'hex://${bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';
  }

  final player = mpv.Player();
  final _states = StreamController<LemonPlayerState>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  LemonPlayerState _state = const LemonPlayerState.idle();
  bool _loaded = false;
  String? get _error => _state.errorMessage;
  mpv.Media? _pendingMedia;

  MpvPlayer({
    this.onNext,
    this.onPrevious,
    this.onQueueItem,
    this.queueIndex,
    this.onPlaybackIntent,
    this.onRetry,
  }) {
    _subscriptions.addAll([
      player.stream.playbackState.listen((_) => _emit()),
      player.stream.playWhenReady.listen((_) => _emit()),
      player.stream.position.listen((_) => _emit()),
      player.stream.buffer.listen((_) => _emit()),
      player.stream.rate.listen((_) => _emit()),
    ]);
  }

  Future<void> open(mpv.Media media) async {
    _pendingMedia = media;
    _loaded = true;
    _state = LemonPlayerState(
      playing: false,
      processingState: LemonProcessingState.loading,
      position: Duration(milliseconds: media.extras?['start'] as int? ?? 0),
      speed: player.state.rate,
      queueIndex: queueIndex?.call(),
    );
    _states.add(_state);
  }

  void _emit() {
    final state = player.state;
    _state = LemonPlayerState(
      playing: _error == null && state.playWhenReady && !state.completed,
      errorMessage: _error,
      processingState: _error != null
          ? LemonProcessingState.error
          : !_loaded
          ? LemonProcessingState.idle
          : state.completed
          ? LemonProcessingState.completed
          : state.buffering
          ? LemonProcessingState.buffering
          : state.duration == Duration.zero
          ? LemonProcessingState.loading
          : LemonProcessingState.ready,
      position: _error == null ? state.position : _state.position,
      bufferedPosition: state.buffer,
      speed: state.rate,
      queueIndex: queueIndex?.call(),
    );
    _states.add(_state);
  }

  @override
  LemonPlayerState get currentState => _state;
  void fail(Object error) {
    _state = _state.copyWith(errorMessage: '$error');
    _emit();
  }

  void resetFailure() {
    if (_error == null) return;
    // 解析成功不代表解码完成，先解除失败锁定，等待底层报告就绪。
    _state = LemonPlayerState(
      playing: false,
      processingState: LemonProcessingState.loading,
      position: _state.position,
      speed: _state.speed,
      queueIndex: _state.queueIndex,
    );
    _states.add(_state);
  }

  @override
  Stream<LemonPlayerState> get stateStream => _states.stream;
  @override
  Future<void> play() async {
    if (_error != null) {
      await onRetry?.call();
      return;
    }
    onPlaybackIntent?.call(true);
    final media = _pendingMedia;
    if (media != null) {
      _pendingMedia = null;
      // 新曲由同一次加载提交播放意图，不对上一曲的 EOF 状态执行 seek。
      await player.open(media, play: true);
    } else {
      if (player.state.completed) await seek(Duration.zero);
      await player.play();
    }
  }

  @override
  Future<void> pause() {
    onPlaybackIntent?.call(false);
    return player.pause();
  }

  @override
  Future<void> skipToNext() async => onNext?.call();
  @override
  Future<void> skipToPrevious() async => onPrevious?.call();
  @override
  Future<void> skipToQueueItem(int index) async => onQueueItem?.call(index);
  @override
  Future<void> stop() async {
    onPlaybackIntent?.call(false);
    _pendingMedia = null;
    _loaded = false;
    _state = const LemonPlayerState.idle();
    await player.stop();
    _emit();
  }

  @override
  Future<void> seek(Duration position) async {
    final media = _pendingMedia;
    if (media != null) {
      _pendingMedia = media.copyWith(
        extras: {...?media.extras, 'start': position.inMilliseconds},
      );
      _state = _state.copyWith(position: position);
      _states.add(_state);
    } else {
      await player.seek(position, relative: false, exact: true);
    }
  }

  @override
  Future<void> setSpeed(double speed) => player.setRate(speed);
  double _userVolume = 1;
  double _duckVolume = 1;
  Future<void> setUserVolume(double value) async {
    _userVolume = value;
    await player.setVolume(_userVolume * _duckVolume * 100);
  }

  Future<void> setMuted(bool value) => player.setMute(value);
  static mpv.FirequalizerSettings equalizerSettings(
    bool enabled,
    List<double> gains,
  ) => mpv.FirequalizerSettings(
    enabled: enabled,
    gain_entry: [
      for (var i = 0; i < EqualizerController.frequencies.length; i++)
        'entry(${EqualizerController.frequencies[i]},${gains[i]})',
    ].join(';'),
  );

  Future<void> setEqualizer(bool enabled, List<double> gains) =>
      player.updateAudioEffects(
        (effects) => effects.copyWith(
          // gain_entry 支持 af-command；预设和频段变化不再重建整条 af。
          firequalizer: equalizerSettings(enabled, gains),
        ),
      );
  @override
  Future<void> setVolume(double volume) async {
    _duckVolume = volume;
    await player.setVolume(_userVolume * _duckVolume * 100);
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await player.dispose();
    await _states.close();
  }
}
