import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/home/home_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_background_color.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  ///声明变量
  Timer? _timer;

  ///记录当前的时间
  RxInt time = RxInt(1 * 600);

  // RxInt currentTimer = RxInt(0);
  RxInt totalTime = RxInt(1 * 600);

  bool firstIn = true;

  @override
  void initState() {
    super.initState();

    firstIn = Sp.getBool(Constant.KEY_FIRST_IN) ?? true;

    Future.delayed(Duration(milliseconds: 400)).then((v) {
      startCountdown();
    });
  }

  // 启动倒计时
  void startCountdown() {
    ///循环执行
    ///间隔1秒
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (time.value > 0) {
        time.value = time.value - 20;
      } else {
        _timer?.cancel();
        Get.offAndToNamed(Routes.home);
      }
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
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Obx(() => CircularProgressIndicator(
                        strokeWidth: 3,
                        backgroundColor: Colors.black12,
                        value: time.value / totalTime.value,
                      )),
                  Text(
                    "跳过",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                _timer?.cancel();
                Get.offAndToNamed(Routes.home);
              },
            ),
          ),
        ),
      ),
      body: HyperBackground(
        child: SafeArea(
          child: Column(
            children: [
              Gap(32),
              Expanded(
                  child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 第一列
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('个', style: Theme.of(context).textTheme.headlineMedium),
                        Text('性', style: Theme.of(context).textTheme.headlineMedium),
                        Text('，', style: Theme.of(context).textTheme.headlineMedium),
                        Text('定', style: Theme.of(context).textTheme.headlineMedium),
                        Text('制', style: Theme.of(context).textTheme.headlineMedium),
                        Text('', style: Theme.of(context).textTheme.headlineMedium),
                        Text('', style: Theme.of(context).textTheme.headlineMedium),
                        Text('', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                    SizedBox(width: 40), // 列之间的间距
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('', style: Theme.of(context).textTheme.headlineMedium),
                        Text('', style: Theme.of(context).textTheme.headlineMedium),
                        Text('', style: Theme.of(context).textTheme.headlineMedium),
                        Text('', style: Theme.of(context).textTheme.headlineMedium),
                        Text('畅', style: Theme.of(context).textTheme.headlineMedium),
                        Text('享', style: Theme.of(context).textTheme.headlineMedium),
                        Text('音', style: Theme.of(context).textTheme.headlineMedium),
                        Text('乐', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ],
                ),
              )),
              Container(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/app_logo.png", width: 50, height: 50),
                    Text("MixMusic", style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
