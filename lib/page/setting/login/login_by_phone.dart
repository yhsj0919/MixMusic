import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/message.dart';

class LoginByPhonePage extends StatefulWidget {
  const LoginByPhonePage({super.key});

  @override
  State<LoginByPhonePage> createState() => _LoginByPhonePageState();
}

class _LoginByPhonePageState extends State<LoginByPhonePage> {
  MusicApi? api;
  RxnString cookie = RxnString();
  var controller = TextEditingController(text: "");
  UserController userController = Get.put(UserController());
  PluginsInfo? plugin;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isButtonDisabled = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    plugin = Get.arguments;

    api = ApiFactory.api(package: plugin?.package ?? "");
  }

  // 模拟发送验证码的函数
  void _sendCode() {
    final phone = _phoneController.text;

    // 简单的手机号格式校验
    if (phone.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      showError("请输入有效的手机号");
      return;
    }

    // 启动倒计时
    setState(() {
      _isButtonDisabled = true;
    });

    _startCountdown();

    api?.sendPhoneCode(phone: phone).then((v) {
      showInfo("验证码已发送!");
    }).catchError((e) {
      _stopCountdown();

      showError("验证码发送失败!");
    });
  }

  // 启动倒计时
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _isButtonDisabled = false;
          _countdown = 60;
        });
        _timer?.cancel();
      }
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    setState(() {
      _isButtonDisabled = false;
      _countdown = 60;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    if (_timer?.isActive == true) {
      _timer?.cancel();
    }
    super.dispose();
  }

  void _loginByCode() {
    final phone = _phoneController.text;
    final code = _codeController.text;

    // 简单的手机号格式校验
    if (phone.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      showError("请输入有效的手机号");
      return;
    }

    if (code.isEmpty) {
      showError("请输入验证码");
      return;
    }

    api?.loginByPhone(phone: phone, code: code).then((v) {
      showInfo("登录成功!");
    }).catchError((e) {
      print(e);
      _stopCountdown();
      showInfo("登录失败!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          HyperAppbar(
            title: "验证码登录",
          ),
          SliverGap(100),
          HyperGroup(
            children: [
              Gap(12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    hintText: '请输入手机号',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          hintText: '请输入验证码',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      )),
                      Gap(12),
                      FilledButton(
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                          padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20, vertical: 23)),
                        ),
                        onPressed: _isButtonDisabled ? null : _sendCode,
                        child: Text(_isButtonDisabled ? '重新获取($_countdown)' : '获取验证码'),
                      ),
                    ],
                  )),
            ],
          ),
          SliverGap(16),
          SliverToBoxAdapter(
            child: Container(
                // height: 45,
                margin: EdgeInsets.all(12),
                child: FilledButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0), // 设置圆角
                        ),
                      ),
                      padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20, vertical: 20)),
                    ),
                    onPressed: () {
                      _loginByCode();
                    },
                    child: Text("登录"))),
          ),
        ],
      ),
    );
  }
}
