import 'package:lemon_x/lemon_x.dart';

import 'player_controller.dart';

class EqualizerController extends LxController implements LxDisposable {
  EqualizerController(this.player);
  final PlayerController player;
  static const frequencies = [
    65,
    92,
    131,
    185,
    262,
    370,
    523,
    740,
    1047,
    1480,
    2093,
    2960,
    4186,
    5920,
    8372,
    11840,
    16744,
    20000,
  ];
  static const presets = {
    '平直': [0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    '低音增强': [5.0, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    '人声': [-2.0, -2, -1, 0, 0, 1, 2, 3, 3, 3, 2, 1, 0, -1, -1, -2, -2, -2],
    '高音增强': [0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 4, 4, 3, 2],
    '流行': [2.0, 2, 1, 0, -1, -1, 0, 1, 2, 2, 2, 1, 1, 2, 2, 1, 0, 0],
    '摇滚': [4.0, 4, 3, 2, 1, 0, -1, -1, 0, 1, 2, 3, 3, 3, 2, 2, 1, 0],
    '古典': [1.0, 1, 1, 0, 0, 0, -1, -1, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0],
    '爵士': [2.0, 2, 1, 1, 0, 0, 1, 1, 2, 2, 1, 1, 2, 2, 1, 1, 0, 0],
    '电子': [5.0, 4, 3, 2, 0, -1, -2, -2, -1, 0, 1, 2, 3, 4, 3, 2, 1, 0],
    '舞曲': [4.0, 4, 3, 3, 2, 1, 0, -1, -1, 0, 1, 2, 2, 3, 2, 1, 0, 0],
    '民谣': [-1.0, -1, 0, 0, 1, 2, 2, 2, 2, 1, 1, 2, 2, 1, 1, 0, -1, -1],
    '原声': [0.0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 2, 2, 2, 1, 1, 0, 0],
    '柔和': [1.0, 1, 1, 1, 1, 0, 0, 0, -1, -1, -2, -2, -3, -3, -4, -4, -4, -4],
    '明亮': [-2.0, -2, -1, -1, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 3, 2, 1, 0],
    '低音减弱': [-6.0, -5, -4, -3, -2, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    '高音减弱': [0.0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -2, -3, -4, -4, -5, -5, -6],
  };
  late final enabled = own(
    (player.preferences?.getBool('equalizerEnabled') ?? false).obs,
  );
  late final gains = own(
    Rx<List<double>>(
      player.preferences
              ?.getStringList('equalizerGains')
              ?.map(double.parse)
              .toList() ??
          List.filled(frequencies.length, 0),
    ),
  );
  late final preset = own(
    (player.preferences?.getString('equalizerPreset') ?? '平直').obs,
  );

  Future<void> _save() async {
    await player.preferences?.setBool('equalizerEnabled', enabled.value);
    await player.preferences?.setStringList(
      'equalizerGains',
      gains.value.map((value) => '$value').toList(),
    );
    await player.preferences?.setString('equalizerPreset', preset.value);
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _save();
    await apply();
  }

  Future<void> setBand(int index, double gain) async {
    gains.value = [...gains.value]..[index] = gain.clamp(-12.0, 12.0);
    preset.value = '自定义';
    await _save();
    await apply();
  }

  Future<void> selectPreset(String name) async {
    gains.value = presets[name]!.map((value) => value.toDouble()).toList();
    preset.value = name;
    await _save();
    await apply();
  }

  Future<void> apply() async {
    player.controlError.value = '';
    try {
      await player.engine?.setEqualizer(enabled.value, gains.value);
    } catch (error, stack) {
      player.reportControlError('均衡器设置失败', error, stack);
    }
  }

  @override
  Future<void> dispose() => disposeController();
}
