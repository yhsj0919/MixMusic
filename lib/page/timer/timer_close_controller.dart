import 'dart:async';

import 'package:get/get.dart';
import 'package:mix_music/player/Player.dart';

class TimeCloseController extends GetxController {
  final RxInt selectTime = RxInt(0);
  final RxBool startTimer = RxBool(false);
  final RxBool stopWithTimer = RxBool(false);
  final RxBool shouldClose = RxBool(false);
  Timer? _timer;
  final RxInt time = RxInt(0);
  final RxInt minute = RxInt(0);
  final RxInt seconds = RxInt(0);

  @override
  void onInit() {
    super.onInit();

    startTimer.stream.listen((v) {
      if (v) {
        startCountdown();
        print('开始倒计时');
      } else {
        print('关闭倒计时');
        stopCountdown();
      }
    });
  }

  // 启动倒计时
  void startCountdown() {
    shouldClose.value = false;
    time.value = selectTime.value * 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (time.value > 0) {
        time.value--;
        formatMinutesAndSeconds(time.value);
      } else {
        _timer?.cancel();
        if (!stopWithTimer.value) {
          Player.pause();
          print('结束倒计时，关闭音乐');
        } else {
          shouldClose.value = true;
          print('等待当前音乐播放完成');
        }
      }
    });
  }

  void stopCountdown() {
    shouldClose.value = false;
    _timer?.cancel();
    time.value = 0;
  }

  void formatMinutesAndSeconds(int mySeconds) {
    int myMinutes = mySeconds ~/ 60;
    int remainingSeconds = mySeconds % 60;

    minute.value = myMinutes;
    seconds.value = remainingSeconds;
  }

  @override
  void onClose() {
    super.onClose();
    stopCountdown();
  }
}
