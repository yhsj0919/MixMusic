import 'dart:async';

class DebounceHelper {
  Timer? _timer;

  // 防抖函数，接受一个回调和延迟时间
  void debounce(Function callback, {Duration duration = const Duration(milliseconds: 300)}) {
    // 如果已有定时器存在，取消它
    _timer?.cancel();

    // 创建一个新的定时器
    _timer = Timer(duration, () {
      callback();
    });
  }

  void cancel() {
    _timer?.cancel();
  }
}
