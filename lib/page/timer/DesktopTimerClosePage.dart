import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';

import 'timer_close_controller.dart';

class DesktopTimerClosePage extends StatefulWidget {
  const DesktopTimerClosePage({super.key});

  @override
  State<DesktopTimerClosePage> createState() => _DesktopTimerClosePageState();
}

class _DesktopTimerClosePageState extends State<DesktopTimerClosePage> {
  TimeCloseController controller = Get.put(TimeCloseController());

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FluentGroup(
          inSliver: false,
          horizontalPadding: 8,
          children: [
            ListTile(
              title: Text("选择时间"),
              trailing: Obx(
                () => ToggleSwitch(
                  onChanged: (select) {
                    controller.startTimer.value = select;
                    if (!select) {
                      controller.selectTime.value = 0;
                      controller.minute.value = 0;
                      controller.seconds.value = 0;
                    }
                  },
                  checked: controller.startTimer.value,
                ),
              ),
            ),
            Obx(
              () => Slider(
                value: controller.selectTime.value.toDouble(),
                min: 0,
                max: 90,
                divisions: 90,
                label: "${controller.selectTime.toStringAsFixed(0)}分钟",
                onChanged: (double value) {
                  setState(() {
                    controller.selectTime.value = value.toInt();
                  });
                },
                onChangeEnd: (double value) {
                  controller.startTimer.update((v) {
                    controller.startTimer.value = value > 0;
                  });
                },
              ),
            ),
            Obx(
              () => Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                child: Text('${controller.minute.value}分${controller.seconds.value}秒后关闭音乐'),
              ),
            ),
            Gap(16),
          ],
        ),
        Gap(12),
        FluentGroup(
          horizontalPadding: 8,
          inSliver: false,
          children: [
            ListTile(
              title: Text("播完整首歌再停止播放"),
              trailing: Obx(
                () => ToggleSwitch(
                  checked: controller.stopWithTimer.value,
                  onChanged: (select) {
                    controller.stopWithTimer.value = select;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
