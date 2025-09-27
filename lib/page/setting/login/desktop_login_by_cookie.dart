import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/setting/login/user_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';

class DesktopLoginByCookiePage extends StatefulWidget {
  const DesktopLoginByCookiePage({super.key, required this.plugin});

  final PluginsInfo? plugin;

  @override
  State<DesktopLoginByCookiePage> createState() => _DesktopLoginByCookiePageState();
}

class _DesktopLoginByCookiePageState extends State<DesktopLoginByCookiePage> {
  MusicApi? api;
  RxnString cookie = RxnString();
  var controller = TextEditingController(text: "");
  UserController userController = Get.put(UserController());
  PluginsInfo? plugin;
  ThemeController theme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    plugin = widget.plugin;

    api = ApiFactory.api(package: plugin?.package ?? "");
    getCookie();
  }

  void getCookie() async {
    cookie.value = (await api?.getCookie())?.data ?? "";
    controller.text = cookie.value ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text("Cookie登录"),
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
      content: CustomScrollView(
        slivers: [
          FluentGroup(
            children: [
              Container(
                child: TextBox(maxLines: 16, controller: controller, placeholder: '请输入cookie'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              // height: 45,
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Button(
                style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
                onPressed: () {
                  api?.setCookie(cookie: controller.text);
                  userController.getAllUser().then((v) {
                    context.pop();
                  });
                },
                child: Text("保存"),
              ),
            ),
          ),
          SliverGap(8),
        ],
      ),
    );
  }
}
