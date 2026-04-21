import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/setting/login/user_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/message.dart';

class DesktopLoginByPhonePage extends StatefulWidget {
  const DesktopLoginByPhonePage({super.key, required this.plugin});

  final PluginsInfo? plugin;

  @override
  State<DesktopLoginByPhonePage> createState() => _DesktopLoginByPhonePageState();
}

class _DesktopLoginByPhonePageState extends State<DesktopLoginByPhonePage> {
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
  ThemeController theme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    plugin = widget.plugin;

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

    api
        ?.sendPhoneCode(phone: phone)
        .then((v) {
          showInfo("验证码已发送!");
        })
        .catchError((e) {
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

    api
        ?.loginByPhone(phone: phone, code: code)
        .then((v) {
          showInfo("登录成功!");
          userController.getAllUser().then((v) {
            Get.back();
          });
        })
        .catchError((e) {
          print(e);
          _stopCountdown();
          showError(e);
        });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text("验证码登录"),
        leading: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
          child: IconButton(
            icon: Icon(FluentIcons.back),
            onPressed: () {
              context.pop();
            },
          ),
        ),
      ),
      children: [
        Gap(100),
        Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: InfoLabel(
              label: '手机号',
              child: TextBox(controller: _phoneController, keyboardType: TextInputType.phone, placeholder: '请输入手机号'),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: InfoLabel(
                    label: '验证码',
                    child: TextBox(controller: _codeController, keyboardType: TextInputType.number, placeholder: '请输入验证码'),
                  ),
                ),
                InfoLabel(
                  label: '',
                  child: Button(
                    style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 8))),
                    onPressed: _isButtonDisabled ? null : _sendCode,
                    child: Text(_isButtonDisabled ? '重新获取($_countdown)' : '获取验证码'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap(8),
        Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(12),
            child: Button(
              style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 8))),
              onPressed: () {
                _loginByCode();
              },
              child: Text("登录"),
            ),
          ),
        ),
      ],
    );
  }
}
