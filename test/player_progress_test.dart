import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' as mpv;
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/player/music_cache.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('same-duration replay restores progress after clearing', () async {
    mpv.MpvAudioKit.ensureInitialized(
      libmpv: File('build/windows/x64/runner/Debug/libmpv.dll').absolute.path,
    );
    final directory = await Directory.systemTemp.createTemp('player-progress-');
    addTearDown(() => directory.delete(recursive: true));
    final plugins = PluginController(store: JsExtensionMemoryStore());
    addTearDown(plugins.disposeController);
    final controller = PlayerController(
      plugins,
      cache: MusicCache(directory: directory),
    );
    addTearDown(controller.disposeController);
    final adapter = controller.engine = MpvPlayer();
    await adapter.player.setRawProperty('ao', 'null');
    final states = adapter.stateStream.listen(controller.updateState);
    final durations = adapter.player.stream.duration.listen(
      (value) => controller.duration.value = value,
    );
    addTearDown(states.cancel);
    addTearDown(durations.cancel);
    final uri = File('E:/lemon_audio/example/assets/test-tone.wav').uri
        .toString();
    for (var i = 0; i < 2; i++) {
      await adapter.open(mpv.Media(uri));
      await adapter.play();
      await adapter.player.stream.position
          .firstWhere(
            (value) =>
                value > const Duration(milliseconds: 400) &&
                adapter.player.state.playing,
          )
          .timeout(const Duration(seconds: 8));
      expect(controller.position.value, greaterThan(Duration.zero));
      expect(
        controller.duration.value,
        greaterThan(Duration.zero),
        reason: '第 ${i + 1} 次播放必须恢复总时长',
      );
      await adapter.stop();
      await controller.clearQueue();
      expect(controller.duration.value, Duration.zero);
    }
  }, skip: !const bool.fromEnvironment('MPV_SMOKE'));
}
