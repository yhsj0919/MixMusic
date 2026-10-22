import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/player/equalizer_controller.dart';

class EqualizerPage extends StatefulWidget {
  const EqualizerPage({super.key, required this.controller});
  final EqualizerController controller;

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends State<EqualizerPage> {
  int? editingBand;
  double draft = 0;

  @override
  Widget build(BuildContext context) {
    final eq = widget.controller;
    return HyperScaffold(
      appBar: HyperAppBar(
        title: const HyperText('均衡器'),
        automaticallyImplyLeading: false,
        leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
            ? null
            : HyperIconButton.ghost(
                tooltip: '返回',
                icon: const HyperIcon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/playing'),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Obx(
            () => HyperListTile(
              title: const HyperText('启用均衡器'),
              subtitle: HyperText(eq.preset.value),
              trailing: HyperSwitch(
                value: eq.enabled.value,
                onChanged: eq.setEnabled,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in EqualizerController.presets.keys)
                HyperButton.tonal(
                  onPressed: () => eq.selectPreset(name),
                  label: HyperText(name),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const HyperText('频段增益：−12 至 +12 dB，松手生效。提升增益可能产生失真，请适当降低音量。'),
          for (
            var index = 0;
            index < EqualizerController.frequencies.length;
            index++
          )
            Obx(() {
              final gain = editingBand == index ? draft : eq.gains.value[index];
              return Column(
                children: [
                  HyperListTile(
                    title: HyperText(
                      '${EqualizerController.frequencies[index]} Hz',
                    ),
                    trailing: HyperText('${gain.toStringAsFixed(1)} dB'),
                  ),
                  HyperSlider(
                    value: (gain + 12) / 24,
                    onChanged: (value) => setState(() {
                      editingBand = index;
                      draft = value * 24 - 12;
                    }),
                    onChangeEnd: (value) {
                      eq.setBand(index, value * 24 - 12);
                      setState(() => editingBand = null);
                    },
                  ),
                ],
              );
            }),
          Obx(
            () => eq.player.controlError.value.isEmpty
                ? const SizedBox.shrink()
                : HyperText(eq.player.controlError.value),
          ),
        ],
      ),
    );
  }
}
