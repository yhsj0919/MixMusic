import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import '../../widgets/hyper/hyper_group.dart';
import 'timer_close_controller.dart';

class TimerClosePage extends StatefulWidget {
  const TimerClosePage({super.key});

  @override
  State<TimerClosePage> createState() => _TimerClosePageState();
}

class _TimerClosePageState extends State<TimerClosePage> {
  TimeCloseController controller = Get.put(TimeCloseController());

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text("定时关闭"),
        ),
        HyperGroup(
          inSliver: false,
          children: [
            ListTile(
              titleTextStyle: Theme.of(context).listTileTheme.titleTextStyle?.copyWith(fontSize: 14),
              title: Text("选择时间"),
              trailing: Obx(() => Switch(
                  value: controller.startTimer.value,
                  onChanged: (select) {
                    controller.startTimer.value = select;
                  })),
            ),
            Obx(() => Slider(
                  value: controller.selectTime.value.toDouble(),
                  min: 0,
                  max: 90,
                  divisions: 90,
                  label: controller.selectTime.toStringAsFixed(0),
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
                )),
            Obx(
              () => Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerRight,
                  child: Text(
                    style: Theme.of(context).textTheme.bodyMedium,
                    '${controller.minute.value}分${controller.seconds.value}秒后关闭音乐',
                  )),
            ),
            Gap(16)
          ],
        ),
        Gap(12),
        HyperGroup(
          inSliver: false,
          children: [
            ListTile(
              titleTextStyle: Theme.of(context).listTileTheme.titleTextStyle?.copyWith(fontSize: 14),
              title: Text("播完整首歌再停止播放"),
              trailing: Obx(() => Switch(
                  value: controller.stopWithTimer.value,
                  onChanged: (select) {
                    controller.stopWithTimer.value = select;
                  })),
            ),
          ],
        )
      ],
    );
  }
}
