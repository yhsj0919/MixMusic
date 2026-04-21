import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

//延时是为了防止在弹窗关闭时调用back,导致消息无法显示,弹窗无法关闭
void showInfo(dynamic message) {
  toastification.show(
    title: Text('提示'),
    icon: const Icon(Icons.info_outline, color: Colors.black87, size: 30),
    description: Text("$message", style: const TextStyle(color: Colors.black87, fontSize: 16)),
    style: ToastificationStyle.flatColored,
    autoCloseDuration: const Duration(seconds: 3),
    direction: TextDirection.ltr,
    animationDuration: const Duration(milliseconds: 300),
    animationBuilder: (context, animation, alignment, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    alignment: Alignment.topCenter,
    primaryColor: Color(0xccb2e7f5),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  );
}

showError(dynamic message) {
  toastification.show(
    title: Text('错误'),
    icon: const Icon(Icons.cancel_outlined, color: Colors.black87, size: 30),
    description: Text("$message", style: const TextStyle(color: Colors.black87, fontSize: 16)),
    style: ToastificationStyle.flatColored,
    autoCloseDuration: const Duration(seconds: 3),
    direction: TextDirection.ltr,
    animationDuration: const Duration(milliseconds: 300),
    animationBuilder: (context, animation, alignment, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    alignment: Alignment.topCenter,
    primaryColor: Color(0xccfc624d),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  );
}

showWarn(dynamic message) {
  toastification.show(
    title: Text('警告'),
    icon: const Icon(Icons.warning_amber_outlined, color: Colors.black87, size: 30),
    description: Text("$message", style: const TextStyle(color: Colors.black87, fontSize: 16)),
    style: ToastificationStyle.flatColored,
    autoCloseDuration: const Duration(seconds: 3),
    direction: TextDirection.ltr,
    animationDuration: const Duration(milliseconds: 300),
    animationBuilder: (context, animation, alignment, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    alignment: Alignment.topCenter,
    primaryColor: Color(0xccfce38a),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  );
}

showComplete(dynamic message) {
  toastification.show(
    title: Text('提示'),
    icon: const Icon(Icons.check_circle_outlined, color: Colors.black87, size: 30),
    description: Text("$message", style: const TextStyle(color: Colors.black87, fontSize: 16)),
    style: ToastificationStyle.flatColored,
    autoCloseDuration: const Duration(seconds: 3),
    direction: TextDirection.ltr,
    animationDuration: const Duration(milliseconds: 300),
    animationBuilder: (context, animation, alignment, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    alignment: Alignment.topCenter,
    primaryColor: Color(0xcc89d961),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  );
}
