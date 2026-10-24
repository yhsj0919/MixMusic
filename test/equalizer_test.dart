import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' as mpv;
import 'package:mix_music/common/player/equalizer_controller.dart';
import 'package:mix_music/common/player/player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('18-band presets update one runtime curve, not the filter topology', () {
    var previous = mpv.AudioEffects(
      firequalizer: MpvPlayer.equalizerSettings(true, List.filled(18, 0)),
    );
    for (final gains in EqualizerController.presets.values) {
      final values = gains.map((gain) => gain.toDouble()).toList();
      final settings = MpvPlayer.equalizerSettings(true, values);
      final entries = settings.gain_entry.split(';');
      expect(entries, hasLength(18));
      for (var i = 0; i < entries.length; i++) {
        expect(
          entries[i],
          'entry(${EqualizerController.frequencies[i]},${values[i]})',
        );
      }
      final next = previous.copyWith(firequalizer: settings);
      final commands = next.diffCommands(previous);
      expect(commands, isNotNull);
      expect(commands!.length, lessThanOrEqualTo(1));
      if (commands.isNotEmpty) {
        expect(commands.single.label, 'aek_firequalizer');
        expect(commands.single.option, 'gain_entry');
        expect(commands.single.value, settings.gain_entry);
      }
      expect(next.diffCommands(next), isEmpty);
      previous = next;
    }
  });

  test('disabled equalizer retains gains without adding the filter', () {
    final settings = MpvPlayer.equalizerSettings(false, List.filled(18, 6));
    expect(settings.gain_entry, contains('entry(65,6.0)'));
    expect(mpv.AudioEffects(firequalizer: settings).toAfChain(), isEmpty);
  });

  test(
    'native preset change updates the existing graph during playback',
    () async {
      mpv.MpvAudioKit.ensureInitialized(
        libmpv: File('build/windows/x64/runner/Release/libmpv.dll')
            .absolute
            .path,
      );
      final adapter = MpvPlayer();
      addTearDown(adapter.dispose);
      await adapter.player.setRawProperty('ao', 'null');
      await adapter.setEqualizer(true, List.filled(18, 0));
      final ready = adapter.player.stream.position
          .firstWhere(
            (position) => position >= const Duration(milliseconds: 300),
          )
          .timeout(const Duration(seconds: 10));
      await adapter.open(
        mpv.Media(
          File('E:/lemon_audio/example/assets/test-tone.wav').uri.toString(),
        ),
      );
      await adapter.play();
      await ready;
      final before = await adapter.player.getRawProperty('af');
      for (final preset in ['低音增强', '人声', '平直']) {
        await adapter.setEqualizer(
          true,
          EqualizerController.presets[preset]!
              .map((gain) => gain.toDouble())
              .toList(),
        );
        // af-command 改运行中的滤镜，不重写 af 配置字符串；失败回退重建会改变它。
        expect(await adapter.player.getRawProperty('af'), before);
        expect(adapter.player.state.playWhenReady, isTrue);
      }
      final position = adapter.player.state.position;
      await adapter.player.stream.position
          .firstWhere((value) => value > position)
          .timeout(const Duration(seconds: 5));
      await adapter.pause();
      await adapter.setEqualizer(true, List.filled(18, 2));
      expect(adapter.player.state.playWhenReady, isFalse);
    },
    skip: !const bool.fromEnvironment('MPV_EQ_SMOKE'),
  );
}
