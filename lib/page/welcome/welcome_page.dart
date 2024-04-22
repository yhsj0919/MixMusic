import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/home/home_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/sp.dart';


class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  ///声明变量
  Timer? _timer;

  ///记录当前的时间
  int currentTimer = 0;
  int totalTime = 1000;

  bool firstIn = true;

  @override
  void initState() {
    super.initState();

    firstIn = Sp.getBool(Sp.KEY_FIRST_IN) ?? true;

    ///循环执行
    ///间隔1秒
    _timer = Timer.periodic(const Duration(milliseconds: 5), (timer) {
      ///自增
      currentTimer += 5;

      ///到5秒后停止
      if (currentTimer >= totalTime) {
        _timer?.cancel();
        if (firstIn) {
          Get.offAndToNamed(Routes.permission);
        } else {
          Get.off(const HomePage());
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    ///取消计时器
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          // padding: const EdgeInsets.all(8),
          alignment: Alignment.topRight,
          child: SizedBox(
            height: 30,
            width: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  backgroundColor: Colors.black12,
                  value: currentTimer / totalTime,
                ),
                Text(
                  "${currentTimer ~/ 1000}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Text("MixMusic", style: Theme.of(context).textTheme.displayMedium),
            ),
          ],
        ),
      ),
    );
  }
}
