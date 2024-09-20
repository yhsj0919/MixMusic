import 'package:flutter/material.dart';
import 'package:get/get.dart';

//延时是为了防止在弹窗关闭时调用back,导致消息无法显示,弹窗无法关闭
showInfo(dynamic message) {
  Future.delayed(const Duration(milliseconds: 350)).then(
    (value) => Get.snackbar("提示", "$message",
        maxWidth: 500,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xccb2e7f5),
        animationDuration: const Duration(milliseconds: 300),
        icon: const Icon(Icons.info_outline, size: 30)),
  );
}

showError(dynamic message) {
  print(message);
  Future.delayed(const Duration(milliseconds: 350)).then(
    (value) => Get.snackbar("错误", "$message",
        maxWidth: 500,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xccfeb8ba),
        animationDuration: const Duration(milliseconds: 300),
        icon: const Icon(Icons.cancel_outlined, size: 30)),
  );
}

showWarn(dynamic message) {
  Future.delayed(const Duration(milliseconds: 350)).then(
    (value) => Get.snackbar(
      "警告",
      "$message",
      maxWidth: 500,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xccf9e4c5),
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.warning_amber_outlined, size: 30),
    ),
  );
}

showComplete(dynamic message) {
  Future.delayed(const Duration(milliseconds: 350)).then(
    (value) => Get.snackbar(
      "提示",
      "$message",
      maxWidth: 500,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xccb8f6c3),
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.done, size: 30),
    ),
  );
}
