// import 'dart:io';
// import 'dart:math';
//
// import 'package:audio_service/audio_service.dart';
// import 'package:audio_session/audio_session.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:mix_music/player/Player.dart';
// import 'package:smtc_windows/smtc_windows.dart';
//
// /// An [AudioHandler] for playing a single item.
// class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
//   SMTCWindows? smtc;
//   bool playInterrupted = false;
//   bool isPlaying = false;
//
//   Duration? _tempPosition;
//
//   AudioPlayerHandler() {
//     if (Platform.isWindows) {
//       smtc = SMTCWindows(
//           config: const SMTCConfig(
//             fastForwardEnabled: true,
//             nextEnabled: true,
//             pauseEnabled: true,
//             playEnabled: true,
//             rewindEnabled: true,
//             prevEnabled: true,
//             stopEnabled: true,
//           ),
//           enabled: false);
//     }
//
//     smtc?.buttonPressStream.listen((event) {
//       _tempPosition = null;
//       switch (event) {
//         case PressedButton.play:
//           // Update playback status
//           play();
//           smtc?.setPlaybackStatus(PlaybackStatus.Playing);
//           break;
//         case PressedButton.pause:
//           pause();
//           smtc?.setPlaybackStatus(PlaybackStatus.Paused);
//           break;
//         case PressedButton.next:
//           skipToNext();
//           break;
//         case PressedButton.previous:
//           skipToPrevious();
//           break;
//         case PressedButton.stop:
//           stop();
//           smtc?.setPlaybackStatus(PlaybackStatus.Stopped);
//           smtc?.disableSmtc();
//           break;
//         default:
//           break;
//       }
//     });
//
//     initSession();
//     Player.onPositionChanged.listen((event) {
//       if ((event.inMilliseconds - (_tempPosition?.inMilliseconds ?? 0)).abs() > 50) {
//         playbackState.add(playbackState.value.copyWith(updatePosition: event));
//         smtc?.setPosition(event);
//         _tempPosition = event;
//       }
//     });
//     Player.onDurationChanged.listen((duration) {
//       // print(duration.inMinutes);
//       var data = mediaItem.valueOrNull;
//       if (data != null) {
//         final newMediaItem = data.copyWith(duration: duration);
//         mediaItem.add(newMediaItem);
//       }
//       smtc?.setMinSeekTime(Duration.zero);
//       smtc?.setMaxSeekTime(duration);
//     });
//     Player.onPlayerStateChanged.listen((event) {
//       print('>>>>>>>>>>$event');
//       if (event == PlayerState.playing) {
//         smtc?.setPlaybackStatus(PlaybackStatus.Playing);
//         Player.setActive(true);
//         Future.delayed(Duration(milliseconds: 200)).then((v) {
//           isPlaying = true;
//         });
//       } else if (event == PlayerState.paused) {
//         smtc?.setPlaybackStatus(PlaybackStatus.Paused);
//         isPlaying = false;
//         // Player.setActive(true);
//       } else if (event == PlayerState.stopped) {
//         smtc?.setPlaybackStatus(PlaybackStatus.Stopped);
//         smtc?.disableSmtc();
//         isPlaying = false;
//         // Player.setActive(true);
//       } else {
//         isPlaying = false;
//       }
//
//       playbackState.add(playbackState.value.copyWith(
//         playing: event == PlayerState.playing,
//         processingState: event == PlayerState.paused
//             ? AudioProcessingState.ready
//             : Player.state == PlayerState.playing
//                 ? AudioProcessingState.ready
//                 : AudioProcessingState.idle,
//       ));
//     });
//   }
//
//   ///session监听
//   Future<void> initSession() async {
//     Player.interruptionEventStream.listen((event) {
//       if (event.begin) {
//         switch (event.type) {
//           case AudioInterruptionType.duck:
//             if (Player.getSession().androidAudioAttributes!.usage == AndroidAudioUsage.game) {
//               Player.setVolume(Player.getVolume() / 2);
//             }
//             print('另一个应用程序开始播放音频，我们应该躲避');
//             //
//             break;
//           case AudioInterruptionType.pause:
//           case AudioInterruptionType.unknown:
//             if (isPlaying) {
//               pause();
//               print('另一个应用程序开始播放音频，我们应该暂停');
//             }
//             playInterrupted = true;
//
//             break;
//         }
//       } else {
//         switch (event.type) {
//           case AudioInterruptionType.duck:
//             Player.setVolume(min(1.0, Player.getVolume() * 2));
//             playInterrupted = false;
//             print('中断结束了，我们应该松开');
//             break;
//           case AudioInterruptionType.pause:
//             if (playInterrupted) pause();
//             playInterrupted = false;
//             print('中断结束了，我们应该恢复');
//             break;
//           // The interruption ended and we should resume.
//           case AudioInterruptionType.unknown:
//             print('中断结束了，我们应该恢复');
//             // The interruption ended but we should not resume.
//             break;
//         }
//       }
//     });
//
//     Player.devicesStream.listen((event) {
//       print('devicesStream:$event');
//     });
//
//     Player.becomingNoisyEventStream.listen((_) {
//       print('becomingNoisyEventStream');
//       Player.pause();
//     });
//
//     Player.devicesChangedEventStream.listen((event) {
//       print('Devices added:   ${event.devicesAdded}');
//       print('Devices removed: ${event.devicesRemoved}');
//     });
//   }
//
//   @override
//   Future<void> playMediaItem(MediaItem mediaItem) async {
//     this.mediaItem.add(mediaItem);
//
//     smtc?.updateMetadata(
//       MusicMetadata(
//         title: mediaItem.title,
//         album: mediaItem.album,
//         albumArtist: mediaItem.artist,
//         artist: mediaItem.artist,
//         thumbnail: mediaItem.artUri?.toString(),
//       ),
//     );
//     await smtc?.enableSmtc();
//
//     playbackState.add(playbackState.value.copyWith(
//       controls: [MediaControl.skipToPrevious, MediaControl.play, MediaControl.skipToNext],
//       systemActions: const {MediaAction.skipToPrevious, MediaAction.playPause, MediaAction.skipToNext, MediaAction.seek},
//       androidCompactActionIndices: const [0, 1, 2],
//       processingState: AudioProcessingState.ready,
//     ));
//     isPlaying = false;
//     if (mediaItem.extras?["type"] == "file") {
//       return Player.play(DeviceFileSource(mediaItem.id));
//     } else {
//       return Player.play(UrlSource(mediaItem.id));
//     }
//   }
//
//   @override
//   Future<void> play() async {
//     print('${Player.state}: play');
//     if (Player.state == PlayerState.stopped) {
//       if (mediaItem.valueOrNull != null) {
//         return playMediaItem(mediaItem.valueOrNull!);
//       } else {
//         print('这里不需要播放');
//       }
//     } else if (Player.state == PlayerState.paused) {
//       return Player.resume();
//     }
//   }
//
//   @override
//   Future<void> pause() async {
//     if (Player.state == PlayerState.paused) {
//       Player.resume();
//     } else {
//       Player.pause();
//     }
//     return super.pause();
//   }
//
//   @override
//   Future<void> seek(Duration position) async {
//     Player.seek(position);
//     print('seek$position');
//   }
//
//   @override
//   Future<void> stop() async {
//     Player.stop();
//   }
//
//   @override
//   Future<void> skipToQueueItem(int i) async {
//     print('skipToQueueItem$i');
//   }
//
//   @override
//   Future<void> skipToNext() {
//     Player.next();
//     return super.skipToNext();
//   }
//
//   @override
//   Future<void> skipToPrevious() {
//     Player.previous();
//     return super.skipToPrevious();
//   }
// }
